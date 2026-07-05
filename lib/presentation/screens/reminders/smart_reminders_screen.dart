import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_client.dart';
import '../../../config/routes.dart';
import '../../../domain/models/smart_reminder.dart';
import '../../../repositories/smart_reminder_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/smart_reminder_background_service.dart';
import '../../../services/smart_reminder_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  List<SmartReminder> _reminders = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRealData();
    final userId = AuthService.currentUserId;
    if (userId != null) {
      _getFamilyId().then((familyId) {
        if (familyId != null) {
          SmartReminderService.startPeriodicEvaluation(userId, familyId);
          SmartReminderService.startLocationBasedEvaluation(userId, familyId);
        }
      });
    }
  }

  @override
  void dispose() {
    SmartReminderService.stopAll();
    super.dispose();
  }

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    final profile = await SupabaseConfig.client
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    return profile?['family_id'] as String?;
  }

  Future<void> _loadRealData() async {
    setState(() => _loading = true);
    final familyId = await _getFamilyId();
    if (familyId != null) {
      final reminders = await SmartReminderRepository().getReminders(familyId);
      setState(() {
        _reminders = reminders;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadRealData();
  }

  void _navigateToCreate() {
    context.push(AppRoutes.smartReminderCreate);
  }

  void _navigateToDetail(SmartReminder reminder) {
    context.push('${AppRoutes.smartReminders}/${reminder.id}');
  }

  String _triggerLabel(SmartReminder r) {
    final t = r.triggers;
    final parts = <String>[];
    if (t.location.enabled) parts.add('📍 Lokasyon');
    if (t.time.enabled) parts.add('⏰ Zaman');
    if (t.behavior.enabled) parts.add('🧠 Davranış');
    if (t.composite.enabled) parts.add('🔗 Bileşik');
    return parts.join(' + ');
  }

  Color _statusColor(ReminderState state) {
    switch (state) {
      case ReminderState.active:
        return Colors.green;
      case ReminderState.triggered:
        return Colors.orange;
      case ReminderState.snoozed:
        return Colors.blue;
      case ReminderState.completed:
        return Colors.grey;
      case ReminderState.expired:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF0A0A0F);
    final textColor = const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '🧠 Akıllı Hatırlatıcılar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFE3F2FD), const Color(0xFFF8F9FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStatsCard(isDark, textColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAiSuggestionsCard(isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Aktif Hatırlatıcılar (${_reminders.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (_loading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final reminder = _reminders[index];
                  return _buildReminderCard(reminder, isDark, textColor);
                },
                childCount: _reminders.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).yeniHatirlatici),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark, Color textColor) {
    final activeCount = _reminders.where((r) => r.status.state == ReminderState.active).length;
    final totalTriggers = _reminders.fold<int>(0, (sum, r) => sum + r.status.triggerCount);
    final avgRate = _reminders.isEmpty
        ? 0
        : _reminders.fold<double>(0, (sum, r) => sum + r.status.completionRate) / _reminders.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Aktif', '$activeCount', Icons.notifications_active, Colors.green),
          _buildStatItem('Tetiklenme', '$totalTriggers', Icons.flash_on, Colors.orange),
          _buildStatItem('Başarı', '%${avgRate.toStringAsFixed(0)}', Icons.trending_up, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAiSuggestionsCard(bool isDark, Color textColor) {
    final suggestions = [
      _AiSuggestion(
        icon: '💡',
        title: 'Çocuk okuldan gelince su içir',
        subtitle: 'Lokasyon: Okul çıkışı pattern',
      ),
      _AiSuggestion(
        icon: '💡',
        title: 'Akşam yemeğinden önce 1 saat hazırlık',
        subtitle: 'Zaman: 17:00, Görev: Yemek',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple[400]),
              const SizedBox(width: 8),
              Text(
                'AI Önerileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => _buildSuggestionItem(s, isDark)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(_AiSuggestion s, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(s.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  s.subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
            },
            child: Text(AppLocalizations.of(context).add),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(SmartReminder reminder, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFFE5E7EB),
        child: InkWell(
          onTap: () => _navigateToDetail(reminder),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(reminder.status.state),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _triggerLabel(reminder),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildBadge(
                      '📊 Başarı: %${reminder.status.completionRate.toStringAsFixed(0)}',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      '🔔 ${reminder.status.triggerCount} kez',
                      Colors.orange,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _navigateToDetail(reminder),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _deleteReminder(reminder),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _deleteReminder(SmartReminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).hatirlaticiyiSil),
        content: Text('"${reminder.title}" silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context).cancel)),
          TextButton(
            onPressed: () async {
              setState(() => _reminders.removeWhere((r) => r.id == reminder.id));
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              await SmartReminderRepository().delete(reminder.id);
              await SmartReminderBackgroundService.cancelReminder(reminder.id);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestion {
  final String icon;
  final String title;
  final String subtitle;

  _AiSuggestion({required this.icon, required this.title, required this.subtitle});
}
