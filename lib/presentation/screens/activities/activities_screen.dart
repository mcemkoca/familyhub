import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/settings/screen_header.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(recentActivityProvider);
    final bg = const Color(0xFF0A0A0F);

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).actTitle,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: activitiesAsync.when(
        data: (activities) => ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return ActivityCard(activity: activities[index]);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AppLocalizations.of(context).srError('$e'))),
      ),
    );
  }
}
