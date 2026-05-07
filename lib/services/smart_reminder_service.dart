import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../domain/models/smart_reminder.dart';
import '../domain/models/context_snapshot.dart';
import '../domain/models/reminder_interaction.dart';
import '../repositories/smart_reminder_repository.dart';
import '../repositories/context_snapshot_repository.dart';
import '../repositories/reminder_interaction_repository.dart';
import 'notification_service.dart';
import 'location_service.dart';

/// Core engine for context-aware smart reminders.
/// Evaluates triggers based on location, time, and behavior context.
class SmartReminderService {
  static final _reminderRepo = SmartReminderRepository();
  static final _contextRepo = ContextSnapshotRepository();
  static final _interactionRepo = ReminderInteractionRepository();

  static Timer? _evaluationTimer;
  static StreamSubscription<Position>? _locationSub;

  static final _bannerController = StreamController<SmartReminder>.broadcast();
  static Stream<SmartReminder> get bannerStream => _bannerController.stream;

  // ── LIFECYCLE ─────────────────────────────────────────────────────────

  static void startPeriodicEvaluation(String memberId, String familyId) {
    _evaluationTimer?.cancel();
    _evaluationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      evaluateReminders(memberId, familyId);
    });
  }

  static void startLocationBasedEvaluation(String memberId, String familyId) {
    _locationSub?.cancel();
    _locationSub = LocationService.locationStream.listen((position) async {
      await evaluateReminders(memberId, familyId);
    });
  }

  static void stopAll() {
    _evaluationTimer?.cancel();
    _locationSub?.cancel();
  }

  // ── MAIN EVALUATION ───────────────────────────────────────────────────

  static Future<void> evaluateReminders(
    String memberId,
    String familyId,
  ) async {
    try {
      final context = await _collectCurrentContext(memberId, familyId);
      await _contextRepo.save(context);

      final activeReminders = await _reminderRepo.getActiveReminders(familyId);

      for (final reminder in activeReminders) {
        // Only evaluate if this member is a target
        if (!_isTargetMember(reminder, memberId)) continue;

        final score = await _calculateTriggerScore(reminder, context, memberId);
        final threshold = _getThreshold(reminder);

        if (score >= threshold) {
          await _triggerReminder(reminder, context, score, memberId);
        }
      }
    } catch (e) {
      // Silently fail to avoid crashes
    }
  }

  // ── CONTEXT COLLECTION ────────────────────────────────────────────────

  static Future<ContextSnapshot> _collectCurrentContext(
    String memberId,
    String familyId,
  ) async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (_) {}

    final now = DateTime.now();

    return ContextSnapshot(
      id: '',
      memberId: memberId,
      familyId: familyId,
      timestamp: now,
      location: position != null
          ? LocationContext(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              speed: position.speed,
              heading: position.heading,
            )
          : const LocationContext(latitude: 0, longitude: 0),
      time: TimeContext.now(),
      activity: const ActivityContext(
        detectedActivity: DetectedActivity.still,
        confidence: 0.5,
      ),
      device: const DeviceContext(),
      environment: const EnvironmentContext(),
      cognitive: _estimateCognitiveState(memberId),
      social: const SocialContext(),
    );
  }

  static CognitiveContext _estimateCognitiveState(String memberId) {
    final hour = DateTime.now().hour;
    // Simple heuristic energy estimation
    double energy;
    if (hour >= 7 && hour <= 10) {
      energy = 85;
    } else if (hour >= 11 && hour <= 14) {
      energy = 70;
    } else if (hour >= 15 && hour <= 18) {
      energy = 60;
    } else if (hour >= 19 && hour <= 22) {
      energy = 50;
    } else {
      energy = 30;
    }

    return CognitiveContext(
      estimatedEnergy: energy,
      estimatedMood: energy > 60
          ? EstimatedMood.positive
          : EstimatedMood.neutral,
      estimatedAvailability: energy > 40
          ? EstimatedAvailability.free
          : EstimatedAvailability.busy,
    );
  }

  // ── TRIGGER SCORING ───────────────────────────────────────────────────

  static Future<double> _calculateTriggerScore(
    SmartReminder reminder,
    ContextSnapshot context,
    String memberId,
  ) async {
    final triggers = reminder.triggers;
    var totalScore = 0.0;
    var triggerCount = 0;

    // A. Location trigger
    if (triggers.location.enabled) {
      final score = _evaluateLocationTrigger(
        triggers.location,
        context.location,
      );
      totalScore += score;
      triggerCount++;
    }

    // B. Time trigger
    if (triggers.time.enabled) {
      final score = _evaluateTimeTrigger(triggers.time, context.time);
      totalScore += score;
      triggerCount++;
    }

    // C. Behavior trigger
    if (triggers.behavior.enabled) {
      final score = _evaluateBehaviorTrigger(triggers.behavior, context);
      totalScore += score;
      triggerCount++;
    }

    if (triggerCount == 0) return 0.0;

    // D. Composite logic
    double score;
    if (triggers.composite.enabled) {
      if (triggers.composite.logic == CompositeLogic.and_) {
        score = totalScore / triggerCount;
        if (score < 0.7) score = 0;
      } else {
        score = totalScore / triggerCount;
      }
    } else {
      score = totalScore / triggerCount;
    }

    // E. Context sensitivity adjustments
    final sensitivity = reminder.contextSensitivity;

    // Quiet hours
    if (context.time.isQuietHours && sensitivity.quietHoursRespect) {
      score *= 0.1;
    }

    // Interruptibility
    if (context.cognitive.estimatedAvailability ==
        EstimatedAvailability.focused) {
      score *= (1 - sensitivity.interruptibilityThreshold / 100);
    }

    // Low energy
    if (context.cognitive.estimatedEnergy < 30) {
      score *= 0.5;
    }

    // F. Heuristic personalization
    final heuristicScore = await _heuristicScore(
      reminder.id,
      memberId,
      context,
    );
    score = score * 0.6 + heuristicScore * 0.4;

    return score.clamp(0.0, 1.0);
  }

  // ── LOCATION TRIGGER EVALUATION ───────────────────────────────────────

  static double _evaluateLocationTrigger(
    LocationTrigger trigger,
    LocationContext context,
  ) {
    if (trigger.geofence == null) return 0.0;

    final distance = Geolocator.distanceBetween(
      context.latitude,
      context.longitude,
      trigger.geofence!.latitude,
      trigger.geofence!.longitude,
    );

    switch (trigger.type) {
      case LocationTriggerType.enter:
        if (distance <= trigger.geofence!.radiusMeters) return 1.0;
        if (distance <= trigger.proximityMeters) {
          return 1.0 - (distance / trigger.proximityMeters);
        }
        return 0.0;

      case LocationTriggerType.exit:
        return distance > trigger.geofence!.radiusMeters ? 1.0 : 0.0;

      case LocationTriggerType.nearby:
        if (distance <= trigger.proximityMeters) {
          return 1.0 - (distance / trigger.proximityMeters);
        }
        return 0.0;

      case LocationTriggerType.leaveHome:
        if (context.placeType == 'home' && (context.speed ?? 0) > 5) {
          return 1.0;
        }
        return 0.0;

      case LocationTriggerType.arriveWork:
        if (context.placeType == 'work' && distance < 50) {
          return 1.0;
        }
        return 0.0;
    }
  }

  // ── TIME TRIGGER EVALUATION ───────────────────────────────────────────

  static double _evaluateTimeTrigger(TimeTrigger trigger, TimeContext context) {
    final now = DateTime.now();

    switch (trigger.type) {
      case TimeTriggerType.absolute:
        if (trigger.absoluteTime == null) return 0.0;
        final diff = now.difference(trigger.absoluteTime!).abs();
        if (diff.inMinutes <= 5) return 1.0;
        if (diff.inMinutes <= 15) return 0.5;
        return 0.0;

      case TimeTriggerType.relative:
        // Relative triggers are event-dependent; handled elsewhere
        return 0.0;

      case TimeTriggerType.recurring:
        if (trigger.cronExpression == null) return 0.0;
        // Simple cron: "0 8 * * 1-5" => weekday 8:00
        final parts = trigger.cronExpression!.split(' ');
        if (parts.length == 5) {
          final minute = int.tryParse(parts[0]);
          final hour = int.tryParse(parts[1]);
          final dayRange = parts[4];
          if (minute != null && hour != null) {
            final matchesTime = now.minute == minute && now.hour == hour;
            final isWeekday = now.weekday >= 1 && now.weekday <= 5;
            final matchesDay =
                dayRange == '*' ||
                (dayRange == '1-5' && isWeekday) ||
                (dayRange == '6-7' && !isWeekday);
            if (matchesTime && matchesDay) return 1.0;
          }
        }
        return 0.0;

      case TimeTriggerType.smartSuggest:
        if (trigger.smartWindow == null) return 0.0;
        final window = trigger.smartWindow!;
        final currentMinutes = now.hour * 60 + now.minute;
        final startMinutes = window.start.hour * 60 + window.start.minute;
        final endMinutes = window.end.hour * 60 + window.end.minute;

        if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
          final center = (startMinutes + endMinutes) / 2;
          final diff = (currentMinutes - center).abs();
          final halfWidth = (endMinutes - startMinutes) / 2;
          return (1.0 - diff / max(halfWidth, 1)).clamp(0.0, 1.0);
        }
        return 0.0;
    }
  }

  // ── BEHAVIOR TRIGGER EVALUATION ───────────────────────────────────────

  static double _evaluateBehaviorTrigger(
    BehaviorTrigger trigger,
    ContextSnapshot context,
  ) {
    switch (trigger.type) {
      case BehaviorTriggerType.inactivity:
        if (context.activity.detectedActivity == DetectedActivity.still) {
          // We don't track real inactivity duration; assume high if still
          return 0.8;
        }
        return 0.0;

      case BehaviorTriggerType.energyLevel:
        final threshold =
            trigger.conditions
                    .firstWhere(
                      (c) => c.field == 'threshold',
                      orElse: () => const BehaviorCondition(
                        field: 'threshold',
                        operator: 'lt',
                        value: 50,
                      ),
                    )
                    .value
                as num? ??
            50;
        if (context.cognitive.estimatedEnergy <= threshold.toDouble()) {
          return 1.0 -
              (context.cognitive.estimatedEnergy / threshold.toDouble());
        }
        return 0.0;

      case BehaviorTriggerType.weatherChange:
        final condition =
            trigger.conditions
                    .firstWhere(
                      (c) => c.field == 'condition',
                      orElse: () => const BehaviorCondition(
                        field: 'condition',
                        operator: 'eq',
                        value: 'rain',
                      ),
                    )
                    .value
                as String?;
        if (context.environment.weather == condition) return 1.0;
        return 0.0;

      case BehaviorTriggerType.purchaseIntent:
        if (context.location.placeType == 'shopping' ||
            context.location.placeType == 'supermarket') {
          return 0.9;
        }
        return 0.0;

      case BehaviorTriggerType.socialContext:
        final requiredMember =
            trigger.conditions
                    .firstWhere(
                      (c) => c.field == 'memberId',
                      orElse: () => const BehaviorCondition(
                        field: 'memberId',
                        operator: 'eq',
                        value: '',
                      ),
                    )
                    .value
                as String?;
        if (requiredMember != null &&
            context.social.nearbyFamilyMembers.contains(requiredMember)) {
          return 1.0;
        }
        return 0.0;

      default:
        return 0.0;
    }
  }

  // ── HEURISTIC PERSONALIZATION ─────────────────────────────────────────

  static Future<double> _heuristicScore(
    String reminderId,
    String memberId,
    ContextSnapshot context,
  ) async {
    try {
      final interactions = await _interactionRepo.getRecentInteractions(
        reminderId,
        days: 30,
      );
      if (interactions.isEmpty) return 0.5;

      final completed = interactions
          .where((i) => i.action == ReminderAction.completed)
          .toList();
      if (completed.isEmpty) return 0.3;

      // Check if current hour was historically successful
      final currentHour = context.time.hour;
      final hourMatches = completed.where((i) {
        final h = i.context?.time?.hour;
        return h != null && (h - currentHour).abs() <= 1;
      }).length;

      // Check if current place type was historically successful
      final placeType = context.location.placeType;
      final placeMatches = completed.where((i) {
        return i.context?.activity == placeType;
      }).length;

      var score = 0.5;
      if (hourMatches > 0) score += 0.2;
      if (placeMatches > 0) score += 0.2;

      // Completion rate factor
      final completionRate = completed.length / interactions.length;
      score += completionRate * 0.1;

      return score.clamp(0.0, 1.0);
    } catch (_) {
      return 0.5;
    }
  }

  // ── THRESHOLD & TARGET CHECK ──────────────────────────────────────────

  static double _getThreshold(SmartReminder reminder) {
    // Higher threshold for composite triggers, lower for simple ones
    if (reminder.triggers.composite.enabled) return 0.75;
    if (reminder.triggers.behavior.enabled) return 0.6;
    if (reminder.triggers.time.enabled && reminder.triggers.location.enabled) {
      return 0.7;
    }
    return 0.65;
  }

  static bool _isTargetMember(SmartReminder reminder, String memberId) {
    final audience = reminder.targetAudience;
    if (audience.type == TargetAudienceType.smartSelect) return true;
    if (audience.memberIds.isEmpty) return true;
    return audience.memberIds.contains(memberId);
  }

  // ── TRIGGER DELIVERY ──────────────────────────────────────────────────

  static Future<void> _triggerReminder(
    SmartReminder reminder,
    ContextSnapshot context,
    double confidence,
    String memberId,
  ) async {
    final message = _personalizeMessage(reminder, context);

    // Update status
    final newStatus = ReminderStatus(
      state: ReminderState.triggered,
      triggerCount: reminder.status.triggerCount + 1,
      lastTriggered: DateTime.now(),
      completionRate: reminder.status.completionRate,
    );
    await _reminderRepo.updateStatus(reminder.id, newStatus);

    // Log interaction
    await _interactionRepo.logInteraction(
      ReminderInteraction(
        id: '',
        reminderId: reminder.id,
        memberId: memberId,
        timestamp: DateTime.now(),
        action: ReminderAction.clicked,
        context: InteractionContext(
          latitude: context.location.latitude,
          longitude: context.location.longitude,
          time: DateTime.now(),
          activity: context.activity.detectedActivity.name,
        ),
      ),
    );

    // Deliver via notification
    await NotificationService.showInstantNotification(
      title: message.title,
      body: message.body,
      payload: 'smart_reminder:${reminder.id}',
    );

    // Also emit in-app banner
    _bannerController.add(reminder);
  }

  // ── MESSAGE PERSONALIZATION ───────────────────────────────────────────

  static PersonalizedMessage _personalizeMessage(
    SmartReminder reminder,
    ContextSnapshot context,
  ) {
    var title = reminder.title;
    var body = reminder.description ?? '';

    final variables = <String, String>{
      '{location}': context.location.placeName ?? 'burada',
      '{time}': _formatTime(DateTime.now()),
      '{weather}': context.environment.weather ?? 'güzel',
      '{energy}': context.cognitive.estimatedEnergy > 70 ? 'enerjik' : 'rahat',
      '{nearby_member}': context.social.nearbyFamilyMembers.isNotEmpty
          ? context.social.nearbyFamilyMembers.first
          : 'kimse',
    };

    variables.forEach((key, value) {
      title = title.replaceAll(key, value);
      body = body.replaceAll(key, value);
    });

    // Tone adjustment
    if (reminder.personalization.tone == ReminderTone.gentle &&
        context.cognitive.estimatedEnergy < 40) {
      body = 'Biraz dinlenmiş olabilirsin, ama $body';
    }

    if (reminder.personalization.tone == ReminderTone.urgent &&
        context.time.isQuietHours) {
      title = '🔴 $title';
    }

    // Context suffix
    if (reminder.personalization.includeContext &&
        context.location.placeName != null) {
      body += '\n(Şu an ${context.location.placeName}\'dasın)';
    }

    return PersonalizedMessage(
      title: title,
      body: body,
      plainText: '$title: $body',
      suggestedAction: reminder.personalization.suggestedAction,
    );
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── USER ACTIONS ──────────────────────────────────────────────────────

  static Future<void> markCompleted(String reminderId, String memberId) async {
    final reminder = await _reminderRepo.getById(reminderId);
    final interactions = await _interactionRepo.getInteractionsForReminder(
      reminderId,
    );
    final total = interactions.length + 1;
    final completed =
        interactions.where((i) => i.action == ReminderAction.completed).length +
        1;
    final rate = total > 0 ? (completed / total) * 100 : 0.0;

    await _reminderRepo.updateStatus(
      reminderId,
      ReminderStatus(
        state: ReminderState.active,
        triggerCount: reminder.status.triggerCount,
        lastTriggered: reminder.status.lastTriggered,
        completionRate: rate,
      ),
    );

    await _interactionRepo.logInteraction(
      ReminderInteraction(
        id: '',
        reminderId: reminderId,
        memberId: memberId,
        timestamp: DateTime.now(),
        action: ReminderAction.completed,
      ),
    );
  }

  static Future<void> snoozeReminder(
    String reminderId,
    String memberId, {
    int minutes = 10,
  }) async {
    await _reminderRepo.updateStatus(
      reminderId,
      ReminderStatus(
        state: ReminderState.snoozed,
        triggerCount: 0,
        nextScheduled: DateTime.now().add(Duration(minutes: minutes)),
      ),
    );

    await _interactionRepo.logInteraction(
      ReminderInteraction(
        id: '',
        reminderId: reminderId,
        memberId: memberId,
        timestamp: DateTime.now(),
        action: ReminderAction.snoozed,
        snoozeDuration: minutes,
      ),
    );
  }

  static Future<void> dismissReminder(
    String reminderId,
    String memberId,
  ) async {
    await _interactionRepo.logInteraction(
      ReminderInteraction(
        id: '',
        reminderId: reminderId,
        memberId: memberId,
        timestamp: DateTime.now(),
        action: ReminderAction.dismissed,
      ),
    );
  }
}
