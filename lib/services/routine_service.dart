import 'dart:async';
import '../domain/models/routine.dart';
import '../domain/models/routine_template.dart';
import '../repositories/routine_repository.dart';
import 'notification_service.dart';
import 'localization/locale_service.dart';

class RoutineService {
  static String _text(Map<String, String> values) {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return values[lang] ?? values['tr']!;
  }
  static final _repo = RoutineRepository();
  static final _activeRoutines = <String, Routine>{};
  // ignore: close_sinks
  static final _timerController = StreamController<Routine>.broadcast();
  static Stream<Routine> get timerStream => _timerController.stream;

  // ── CRUD OPERATIONS ───────────────────────────────────────────────────

  static Future<List<Routine>> getRoutines(String familyId) async {
    return _repo.getRoutines(familyId);
  }

  static Future<Routine> createRoutine(Routine routine) async {
    return _repo.create(routine);
  }

  static Future<Routine> updateRoutine(Routine routine) async {
    return _repo.update(routine);
  }

  static Future<void> deleteRoutine(String id) async {
    await _repo.delete(id);
  }

  // ── ROUTINE EXECUTION ─────────────────────────────────────────────────

  static Future<void> startRoutine(String routineId) async {
    final routine = await _repo.getById(routineId);
    final now = DateTime.now();

    final updatedSteps = routine.steps.map((s) {
      if (s.order == 0) {
        return s.copyWith(status: StepStatus.inProgress, startedAt: now);
      }
      return s;
    }).toList();

    final updated = routine.copyWith(
      status: RoutineStatus(
        state: RoutineState.active,
        progress: 0,
        currentStep: 0,
        startedAt: now,
        estimatedEnd: now.add(
          Duration(minutes: routine.estimatedTotalDuration),
        ),
      ),
      steps: updatedSteps,
    );

    await _repo.update(updated);
    _activeRoutines[routineId] = updated;

    await NotificationService.showInstantNotification(
      title: _text({'tr': '🚀 ${routine.name} Başladı!', 'en': '🚀 ${routine.name} Started!', 'nl': '🚀 ${routine.name} is gestart!', 'fr': '🚀 ${routine.name} a commencé !'}),
      body: _text({'tr': '${routine.steps.length} adım, ${routine.estimatedTotalDuration} dk', 'en': '${routine.steps.length} steps, ${routine.estimatedTotalDuration} min', 'nl': '${routine.steps.length} stappen, ${routine.estimatedTotalDuration} min', 'fr': '${routine.steps.length} étapes, ${routine.estimatedTotalDuration} min'}),
      payload: 'routine:$routineId',
    );
  }

  static Future<void> completeStep(
    String routineId,
    String stepId,
    String completedBy, {
    String? photoUrl,
    String? voiceNote,
  }) async {
    final routine = await _repo.getById(routineId);
    final now = DateTime.now();

    final steps = routine.steps.map((s) {
      if (s.id == stepId) {
        return s.copyWith(
          status: StepStatus.completed,
          completedAt: now,
          completedBy: completedBy,
          photoUrl: photoUrl ?? s.photoUrl,
          voiceNote: voiceNote ?? s.voiceNote,
        );
      }
      return s;
    }).toList();

    final completedCount = steps
        .where((s) => s.status == StepStatus.completed)
        .length;
    final progress = (completedCount / steps.length) * 100;

    final nextStepIndex = steps.indexWhere(
      (s) =>
          s.status == StepStatus.pending &&
          (s.dependsOn.isEmpty ||
              s.dependsOn.every((dep) {
                final depStep = steps.firstWhere((st) => st.id == dep);
                return depStep.status == StepStatus.completed;
              })),
    );

    final nextSteps = steps.map((s) {
      if (nextStepIndex >= 0 && s.id == steps[nextStepIndex].id) {
        return s.copyWith(status: StepStatus.inProgress, startedAt: now);
      }
      return s;
    }).toList();

    final isComplete = nextSteps.every(
      (s) => s.status == StepStatus.completed || s.status == StepStatus.skipped,
    );

    final updatedStatus = RoutineStatus(
      state: isComplete ? RoutineState.completed : RoutineState.active,
      progress: progress,
      currentStep: isComplete ? steps.length - 1 : nextStepIndex,
      startedAt: routine.status.startedAt,
      estimatedEnd: routine.status.estimatedEnd,
      actualEnd: isComplete ? now : null,
    );

    await _repo.update(
      routine.copyWith(status: updatedStatus, steps: nextSteps),
    );

    if (isComplete) {
      _activeRoutines.remove(routineId);
      await NotificationService.showInstantNotification(
        title: _text({'tr': '🎉 ${routine.name} Tamamlandı!', 'en': '🎉 ${routine.name} Completed!', 'nl': '🎉 ${routine.name} is voltooid!', 'fr': '🎉 ${routine.name} est terminée !'}),
        body: _text(const {'tr': 'Tebrikler, tüm adımları tamamladınız!', 'en': 'Congratulations, you completed every step!', 'nl': 'Gefeliciteerd, je hebt alle stappen voltooid!', 'fr': 'Félicitations, vous avez terminé toutes les étapes !'}),
        payload: 'routine:$routineId:completed',
      );
    }
  }

  static Future<void> skipStep(String routineId, String stepId) async {
    final routine = await _repo.getById(routineId);
    final steps = routine.steps.map((s) {
      if (s.id == stepId) return s.copyWith(status: StepStatus.skipped);
      return s;
    }).toList();
    await _repo.update(routine.copyWith(steps: steps));
  }

  static Future<void> pauseRoutine(String routineId) async {
    final routine = await _repo.getById(routineId);
    await _repo.updateStatus(
      routineId,
      RoutineStatus(
        state: RoutineState.paused,
        progress: routine.status.progress,
        currentStep: routine.status.currentStep,
        startedAt: routine.status.startedAt,
        estimatedEnd: routine.status.estimatedEnd,
      ),
    );
  }

  static Future<void> cancelRoutine(String routineId) async {
    await _repo.updateStatus(
      routineId,
      const RoutineStatus(state: RoutineState.cancelled),
    );
    _activeRoutines.remove(routineId);
  }

  static double calculateProgress(Routine routine) {
    if (routine.steps.isEmpty) return 0;
    final completed = routine.steps
        .where(
          (s) =>
              s.status == StepStatus.completed ||
              s.status == StepStatus.skipped,
        )
        .length;
    return (completed / routine.steps.length) * 100;
  }

  static RoutineStep? getNextStep(Routine routine) {
    return routine.steps.firstWhere(
      (s) =>
          s.status == StepStatus.pending || s.status == StepStatus.inProgress,
      orElse: () => routine.steps.last,
    );
  }

  static RoutineStep? getCurrentStep(Routine routine) {
    try {
      return routine.steps.firstWhere((s) => s.status == StepStatus.inProgress);
    } catch (_) {
      return null;
    }
  }

  // ── TEMPLATE TO ROUTINE ───────────────────────────────────────────────

  static Routine fromTemplate(
    RoutineTemplate template, {
    required String familyId,
    required String createdBy,
    RoutineType type = RoutineType.custom,
  }) {
    return Routine(
      id: '',
      familyId: familyId,
      createdBy: createdBy,
      name: template.name,
      description: template.description,
      icon: template.category == TemplateCategory.health
          ? 'heart'
          : template.category == TemplateCategory.cleaning
          ? 'broom'
          : template.category == TemplateCategory.education
          ? 'book'
          : 'sunrise',
      color: template.category == TemplateCategory.health
          ? '#E91E63'
          : template.category == TemplateCategory.cleaning
          ? '#4CAF50'
          : template.category == TemplateCategory.education
          ? '#2196F3'
          : '#FF9800',
      type: type,
      steps: template.steps
          .asMap()
          .entries
          .map(
            (e) => RoutineStep(
              id: 'step-${e.key + 1}',
              order: e.key,
              title: e.value.title,
              description: e.value.description,
              estimatedDuration: e.value.estimatedDuration,
            ),
          )
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ── AI SUGGESTIONS (Heuristic) ────────────────────────────────────────

  static List<Map<String, dynamic>> generateSuggestions(Routine routine) {
    final suggestions = <Map<String, dynamic>>[];

    final lowCompletionSteps = routine.steps.where((s) {
      // Heuristic: steps with longer duration and no completion
      return s.estimatedDuration > 10 && s.status == StepStatus.pending;
    }).toList();

    if (lowCompletionSteps.isNotEmpty) {
      suggestions.add({
        'type': 'modify_routine',
        'reason': _text({'tr': '${lowCompletionSteps.first.title} adımı uzun sürüyor, süreyi kısaltabilirsiniz', 'en': 'The ${lowCompletionSteps.first.title} step takes a long time; you could shorten it', 'nl': 'De stap ${lowCompletionSteps.first.title} duurt lang; je kunt de duur verkorten', 'fr': 'L’étape ${lowCompletionSteps.first.title} prend beaucoup de temps ; vous pourriez la raccourcir'}),
        'confidence': 0.75,
      });
    }

    if (routine.steps.length > 5) {
      suggestions.add({
        'type': 'reorder_steps',
        'reason': _text(const {'tr': 'Yapay zekânın öğrendiği en uygun sıralamayla rutini %15 hızlandırabilirsiniz', 'en': 'You could speed up the routine by 15% with the AI-optimized order', 'nl': 'Je kunt de routine met 15% versnellen met de door AI geoptimaliseerde volgorde', 'fr': 'Vous pourriez accélérer la routine de 15 % grâce à l’ordre optimisé par l’IA'}),
        'confidence': 0.82,
      });
    }

    if (routine.type == RoutineType.morning) {
      suggestions.add({
        'type': 'new_routine',
        'reason': _text(const {'tr': 'Hafta sonları için “Yavaş Başlangıç” rutini öneriyorum', 'en': 'I recommend a “Slow Start” routine for weekends', 'nl': 'Ik raad een routine “Rustige start” aan voor het weekend', 'fr': 'Je recommande une routine « Démarrage en douceur » pour le week-end'}),
        'confidence': 0.68,
      });
    }

    return suggestions;
  }
}
