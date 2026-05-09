// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../domain/models/calendar_sync.dart';
import '../../../services/calendar_sync_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class CalendarSyncScreen extends StatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen>
    with WidgetsBindingObserver {
  List<CalendarConnection> _connections = [];
  final List<SyncLog> _logs = [];
  bool _loading = false;
  bool? _hasPermission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission(showRequest: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission(showRequest: false);
    }
  }

  Future<void> _checkPermission({bool showRequest = false}) async {
    final has = await CalendarSyncService.hasPermission();
    if (mounted) {
      setState(() => _hasPermission = has);
    }

    if (!has && showRequest && mounted) {
      final granted = await CalendarSyncService.requestPermission();
      if (mounted) {
        setState(() => _hasPermission = granted);
      }
    }
  }

  Future<void> _openSettings() async {
    await CalendarSyncService.openCalendarSettings();
  }

  Future<void> _syncConnection(CalendarConnection conn) async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final end = now.add(const Duration(days: 90));
      final externalEvents = await CalendarSyncService.fetchEvents(
        calendarId: conn.selectedCalendarIds.first,
        start: start,
        end: end,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${externalEvents.length} etkinlik senkronize edildi')),
        );
      }
      setState(() {
        _connections = _connections.map((c) {
          if (c.id == conn.id) {
            return c.copyWith(lastSyncAt: DateTime.now());
          }
          return c;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Senkronizasyon hatası: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRealCalendars() async {
    setState(() => _loading = true);
    try {
      final calendars = await CalendarSyncService.listCalendars();
      if (calendars.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${calendars.length} takvim bulundu')),
        );
      }
    } catch (e) {
      // Demo modda çalışmaya devam et
    }
    setState(() => _loading = false);
  }

  void _showConnectionSettings(CalendarConnection conn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConnectionSettingsSheet(
        connection: conn,
        onUpdate: (updated) {
          setState(() {
            _connections = _connections
                .map((c) => c.id == updated.id ? updated : c)
                .toList();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: AppBar(
        title: const Text('📅 Takvim Senkronizasyonu'),
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.cloudWhite,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.dark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRealCalendars,
            tooltip: 'Takvimleri Tara',
          ),
        ],
      ),
      body: _hasPermission != true
          ? _buildPermissionError(isDark)
          : _buildContent(isDark),
    );
  }

  Widget _buildPermissionError(bool isDark) {
    final bool wasChecked = _hasPermission == false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: AppColors.error.withAlpha(80),
            ),
            const SizedBox(height: 16),
            Text(
              'Takvim Erişim İzni Gerekli',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              wasChecked
                  ? 'Takvim erişim izni gerekli. Ayarlardan izin verin.'
                  : 'Takvimlerinizi senkronize etmek için takvim erişim izni vermeniz gerekiyor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              ),
            ),
            const SizedBox(height: 20),
            if (wasChecked)
              ElevatedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings),
                label: Text(AppLocalizations.of(context).ayarlariAc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _checkPermission(showRequest: true),
                icon: const Icon(Icons.check_circle),
                label: Text(AppLocalizations.of(context).izinVer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık kartı
          _buildHeader(isDark),
          const SizedBox(height: 20),

          // Bağlı takvimler
          _buildConnectedCalendars(isDark),
          const SizedBox(height: 20),

          // Senkronizasyon istatistikleri
          _buildSyncStats(isDark),
          const SizedBox(height: 20),

          // Genel ayarlar
          _buildGeneralSettings(isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sync, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Takvim Senkronizasyonu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Google, Apple ve Outlook takvimlerinizi senkronize edin',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${_connections.where((c) => c.syncEnabled).length} aktif bağlantı',
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCalendars(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(20)
                : Colors.black.withAlpha(5),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bağlı Takvimler',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          if (_connections.isEmpty)
            _buildEmptyConnections(isDark)
          else
            ..._connections.map((c) => _buildConnectionCard(isDark, c)),
        ],
      ),
    );
  }

  Widget _buildEmptyConnections(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.link_off,
            size: 40,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightGray,
          ),
          const SizedBox(height: 10),
          Text(
            'Henüz takvim bağlantısı yok',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(bool isDark, CalendarConnection conn) {
    final providerIcon = _providerIcon(conn.provider);
    final providerColor = _providerColor(conn.provider);
    final isConnected = conn.syncEnabled;
    final lastSync = conn.lastSyncAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? providerColor.withAlpha(40)
              : (isDark ? AppColors.darkBorder : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: providerColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(providerIcon, color: providerColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _providerLabel(conn.provider),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark,
                      ),
                    ),
                    Text(
                      conn.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.success : AppColors.lightGray,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isConnected ? AppColors.success : AppColors.lightGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Seçili takvimler
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: conn.calendars
                .where((c) => conn.selectedCalendarIds.contains(c.id))
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: providerColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: providerColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastSync != null
                      ? '🔄 Son senkronizasyon: ${_timeAgo(lastSync)}'
                      : '🔄 Henüz senkronize edilmedi',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate,
                  ),
                ),
              ),
              if (isConnected)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.settings_outlined,
                      onTap: () => _showConnectionSettings(conn),
                      tooltip: 'Ayarla',
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: _loading ? Icons.hourglass_top : Icons.sync,
                      onTap: _loading ? null : () => _syncConnection(conn),
                      tooltip: 'Şimdi Senkronize',
                      color: AppColors.success,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (color ?? AppColors.cobalt).withAlpha(15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? (color ?? AppColors.cobalt)
              : AppColors.lightGray,
        ),
      ),
    );
  }

  Widget _buildSyncStats(bool isDark) {
    var totalAdded = 0;
    var totalUpdated = 0;
    var totalDeleted = 0;
    for (final log in _logs) {
      totalAdded += log.result.added;
      totalUpdated += log.result.updated;
      totalDeleted += log.result.deleted;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(20)
                : Colors.black.withAlpha(5),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Senkronizasyon İstatistikleri',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('📥 Eklenen', totalAdded.toString(), AppColors.success),
              _statItem(
                '🔄 Güncellenen',
                totalUpdated.toString(),
                AppColors.cobalt,
              ),
              _statItem(
                '🗑️ Silinen',
                totalDeleted.toString(),
                AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam: ${totalAdded + totalUpdated + totalDeleted} etkinlik',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                ),
              ),
              Text(
                'Son hata: Yok',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.slate)),
      ],
    );
  }

  Widget _buildGeneralSettings(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(20)
                : Colors.black.withAlpha(5),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genel Ayarlar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 14),
          _buildSettingTile(
            icon: Icons.schedule,
            title: 'Senkronizasyon sıklığı',
            subtitle: '15 dakikada bir',
            isDark: isDark,
          ),
          _buildSettingTile(
            icon: Icons.merge_type,
            title: 'Çakışma çözümü',
            subtitle: 'Son yazan kazanır',
            isDark: isDark,
          ),
          _buildSettingTile(
            icon: Icons.swap_horiz,
            title: 'Senkronizasyon yönü',
            subtitle: 'Çift yönlü',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cobalt.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.cobalt),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.lightGray),
        ],
      ),
    );
  }

  // ── YARDIMCI ────────────────────────────────────────────────────────────

  IconData _providerIcon(CalendarProvider p) {
    switch (p) {
      case CalendarProvider.google:
        return Icons.g_mobiledata;
      case CalendarProvider.apple:
        return Icons.apple;
      case CalendarProvider.outlook:
        return Icons.outbound;
      case CalendarProvider.local:
        return Icons.calendar_today;
    }
  }

  Color _providerColor(CalendarProvider p) {
    switch (p) {
      case CalendarProvider.google:
        return const Color(0xFF4285F4);
      case CalendarProvider.apple:
        return const Color(0xFF555555);
      case CalendarProvider.outlook:
        return const Color(0xFF0078D4);
      case CalendarProvider.local:
        return AppColors.cobalt;
    }
  }

  String _providerLabel(CalendarProvider p) {
    switch (p) {
      case CalendarProvider.google:
        return 'Google Calendar';
      case CalendarProvider.apple:
        return 'Apple Calendar';
      case CalendarProvider.outlook:
        return 'Outlook Calendar';
      case CalendarProvider.local:
        return 'Yerel Takvim';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}

// ── BAĞLANTI AYARLARI BOTTOM SHEET ──────────────────────────────────────

class _ConnectionSettingsSheet extends StatefulWidget {
  final CalendarConnection connection;
  final ValueChanged<CalendarConnection> onUpdate;

  const _ConnectionSettingsSheet({
    required this.connection,
    required this.onUpdate,
  });

  @override
  State<_ConnectionSettingsSheet> createState() =>
      _ConnectionSettingsSheetState();
}

class _ConnectionSettingsSheetState extends State<_ConnectionSettingsSheet> {
  late CalendarConnection _conn;

  @override
  void initState() {
    super.initState();
    _conn = widget.connection;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _providerIcon(_conn.provider),
                color: _providerColor(_conn.provider),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_providerLabel(_conn.provider)} Ayarları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Senkronize edilecek takvimler
          Text(
            'Senkronize Edilecek Takvimler',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 10),
          ..._conn.calendars.map((c) {
            final selected = _conn.selectedCalendarIds.contains(c.id);
            return CheckboxListTile(
              value: selected,
              onChanged: (v) {
                setState(() {
                  final ids = List<String>.from(_conn.selectedCalendarIds);
                  if (v == true) {
                    ids.add(c.id);
                  } else {
                    ids.remove(c.id);
                  }
                  _conn = _conn.copyWith(selectedCalendarIds: ids);
                });
              },
              title: Text(
                c.name,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                ),
              ),
              subtitle: c.isPrimary
                  ? const Text('Ana takvim', style: TextStyle(fontSize: 12))
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            );
          }),

          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
          const SizedBox(height: 10),

          // Senkronizasyon yönü
          Text(
            'Senkronizasyon Yönü',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          ...SyncDirection.values.map(
            (d) => RadioListTile<SyncDirection>(
              value: d,
              groupValue: _conn.syncDirection,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _conn = _conn.copyWith(syncDirection: v));
                }
              },
              title: Text(_directionLabel(d)),
              dense: true,
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
          const SizedBox(height: 10),

          // Çakışma stratejisi
          Text(
            'Çakışma Çözümü',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          ...ConflictStrategy.values.map(
            (s) => RadioListTile<ConflictStrategy>(
              value: s,
              groupValue: _conn.conflictStrategy,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _conn = _conn.copyWith(conflictStrategy: v));
                }
              },
              title: Text(_conflictLabel(s)),
              dense: true,
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onUpdate(_conn);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: Text(AppLocalizations.of(context).save),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cobalt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              widget.onUpdate(_conn.copyWith(syncEnabled: false));
              Navigator.pop(context);
            },
            icon: const Icon(Icons.link_off, color: AppColors.error),
            label: const Text(
              'Bağlantıyı Kes',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _directionLabel(SyncDirection d) {
    switch (d) {
      case SyncDirection.toExternal:
        return 'FamilyHub → Dışarı';
      case SyncDirection.fromExternal:
        return 'Dışarı → FamilyHub';
      case SyncDirection.bidirectional:
        return 'Çift yönlü';
    }
  }

  String _conflictLabel(ConflictStrategy s) {
    switch (s) {
      case ConflictStrategy.lastWriteWins:
        return 'Son yazan kazanır';
      case ConflictStrategy.manual:
        return 'Her zaman sor';
      case ConflictStrategy.merge:
        return 'Birleştir';
      case ConflictStrategy.sourcePriority:
        return 'Kaynak önceliği';
    }
  }

  IconData _providerIcon(CalendarProvider p) {
    switch (p) {
      case CalendarProvider.google:
        return Icons.g_mobiledata;
      case CalendarProvider.apple:
        return Icons.apple;
      case CalendarProvider.outlook:
        return Icons.outbound;
      case CalendarProvider.local:
        return Icons.calendar_today;
    }
  }

  Color _providerColor(CalendarProvider p) {
    switch (p) {
      case CalendarProvider.google:
        return const Color(0xFF4285F4);
      case CalendarProvider.apple:
        return const Color(0xFF555555);
      case CalendarProvider.outlook:
        return const Color(0xFF0078D4);
      case CalendarProvider.local:
        return AppColors.cobalt;
    }
  }

  String _providerLabel(CalendarProvider p) {
    switch (p) {
      case CalendarProvider.google:
        return 'Google Calendar';
      case CalendarProvider.apple:
        return 'Apple Calendar';
      case CalendarProvider.outlook:
        return 'Outlook Calendar';
      case CalendarProvider.local:
        return 'Yerel Takvim';
    }
  }
}
