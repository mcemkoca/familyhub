// DEPRECATED: This file is not imported anywhere in the project.
// The providers defined here (familyIdProvider, todaySummaryProvider, etc.)
// duplicate those in app_providers.dart. Do not import this file.
// If realtime hub subscription is needed, migrate hubRealtimeProvider
// to app_providers.dart instead.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import '../../domain/entities.dart';
import '../../repositories/hub_repository.dart';
import '../../services/auth_service.dart';

// Family ID provider — read from authenticated user's profile
final familyIdProvider = FutureProvider<String?>((ref) async {
  final userId = AuthService.currentUserId;
  if (userId == null) return null;
  final profile = await SupabaseConfig.safeClient
      ?.from('profiles')
      .select('family_id')
      .eq('id', userId)
      .maybeSingle();
  return profile?['family_id'] as String?;
});

// Hub repository
final hubRepositoryProvider = Provider<HubRepository>((ref) => HubRepository());

// Today summary
final todaySummaryProvider = FutureProvider.autoDispose<TodaySummary>((
  ref,
) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) {
    return const TodaySummary(
      eventCount: 0,
      taskCount: 0,
      unreadMessages: 0,
      onlineMembers: 0,
      totalMembers: 0,
    );
  }
  final repo = ref.watch(hubRepositoryProvider);
  return repo.getTodaySummary(familyId);
});

// Upcoming events
final upcomingEventsProvider = FutureProvider.autoDispose<List<HubEvent>>((
  ref,
) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return [];
  final repo = ref.watch(hubRepositoryProvider);
  return repo.getUpcomingEvents(familyId);
});

// My tasks
final myTasksProvider = FutureProvider.autoDispose<List<HubTask>>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return [];
  final repo = ref.watch(hubRepositoryProvider);
  return repo.getMyTasks(familyId);
});

// Family moods
final familyMoodsProvider = FutureProvider.autoDispose<List<FamilyMood>>((
  ref,
) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return [];
  final repo = ref.watch(hubRepositoryProvider);
  return repo.getRecentMoods(familyId);
});

// Hub realtime subscription — keeps channel alive and invalidates providers on changes
final hubRealtimeProvider = Provider.autoDispose<void>((ref) {
  final familyIdAsync = ref.watch(familyIdProvider);
  final familyId = familyIdAsync.valueOrNull;
  if (familyId == null) return;
  final repo = ref.watch(hubRepositoryProvider);

  final channel = repo.subscribeToHub(
    familyId,
    onEventChange: (_) => ref.invalidate(upcomingEventsProvider),
    onTaskChange: (_) => ref.invalidate(myTasksProvider),
    onMoodChange: (_) => ref.invalidate(familyMoodsProvider),
  );

  ref.onDispose(() => channel.unsubscribe());
});
