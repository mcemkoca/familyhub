// lib/presentation/screens/emergency/sos_settings_screen.dart
// SOS settings: triggers, messages, calls, location, audio, escalation chain

import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'dart:convert';
import '../../../core/app_logger.dart';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';

class SosSettingsScreen extends StatefulWidget {
  const SosSettingsScreen({super.key});

  @override
  State<SosSettingsScreen> createState() => _SosSettingsScreenState();
}

class _SosSettingsScreenState extends State<SosSettingsScreen> {
  bool _panicButton = true;
  bool _voiceCommand = true;
  bool _crashDetection = true;
  bool _inactivity = true;
  int _inactivityMinutes = 60;
  bool _healthEmergency = false;
  bool _smartWatch = false;
  bool _falseAlarmPrevention = true;
  int _confirmationSeconds = 5;

  bool _smsEnabled = true;
  bool _pushEnabled = true;
  bool _whatsappEnabled = true;
  bool _emailEnabled = false;
  bool _telegramEnabled = false;

  bool _autoCall112 = false;
  bool _autoCallFamily = true;
  bool _autoPlayMessage = true;

  bool _locationShare = true;
  int _locationFrequency = 30;
  int _locationDuration = 30;
  bool _includeRoute = true;

  bool _audioRecording = true;
  int _recordingDuration = 5;
  bool _autoUpload = true;
  bool _triggerWords = true;

  /// Kullanıcı-izole anahtar: aynı cihazda hesap değişince önceki kullanıcının
  /// SOS tercihleri yeni kullanıcıya uygulanmamalı.
  static String get _settingsKey {
    final uid = AuthService.currentUserId;
    return (uid == null || uid.isEmpty)
        ? 'sos_settings_anon'
        : 'sos_settings_$uid';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final raw = HiveService.getSetting(_settingsKey);
      if (raw == null || raw.isEmpty) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _panicButton = j['panicButton'] as bool? ?? _panicButton;
        _voiceCommand = j['voiceCommand'] as bool? ?? _voiceCommand;
        _crashDetection = j['crashDetection'] as bool? ?? _crashDetection;
        _inactivity = j['inactivity'] as bool? ?? _inactivity;
        _inactivityMinutes =
            (j['inactivityMinutes'] as num?)?.toInt() ?? _inactivityMinutes;
        _healthEmergency = j['healthEmergency'] as bool? ?? _healthEmergency;
        _smartWatch = j['smartWatch'] as bool? ?? _smartWatch;
        _falseAlarmPrevention =
            j['falseAlarmPrevention'] as bool? ?? _falseAlarmPrevention;
        _confirmationSeconds =
            (j['confirmationSeconds'] as num?)?.toInt() ?? _confirmationSeconds;
        _smsEnabled = j['smsEnabled'] as bool? ?? _smsEnabled;
        _pushEnabled = j['pushEnabled'] as bool? ?? _pushEnabled;
        _whatsappEnabled = j['whatsappEnabled'] as bool? ?? _whatsappEnabled;
        _emailEnabled = j['emailEnabled'] as bool? ?? _emailEnabled;
        _telegramEnabled = j['telegramEnabled'] as bool? ?? _telegramEnabled;
        _autoCall112 = j['autoCall112'] as bool? ?? _autoCall112;
        _autoCallFamily = j['autoCallFamily'] as bool? ?? _autoCallFamily;
        _autoPlayMessage = j['autoPlayMessage'] as bool? ?? _autoPlayMessage;
        _locationShare = j['locationShare'] as bool? ?? _locationShare;
        _locationFrequency =
            (j['locationFrequency'] as num?)?.toInt() ?? _locationFrequency;
        _locationDuration =
            (j['locationDuration'] as num?)?.toInt() ?? _locationDuration;
        _includeRoute = j['includeRoute'] as bool? ?? _includeRoute;
        _audioRecording = j['audioRecording'] as bool? ?? _audioRecording;
        _recordingDuration =
            (j['recordingDuration'] as num?)?.toInt() ?? _recordingDuration;
        _autoUpload = j['autoUpload'] as bool? ?? _autoUpload;
        _triggerWords = j['triggerWords'] as bool? ?? _triggerWords;
      });
    } catch (e) {
      // Bozuk kayıt varsayılanları bozmamalı.
      AppLogger.logBestEffort(e,
          module: 'emergency', operation: 'loadSosSettings');
    }
  }

  Map<String, dynamic> _toJson() => {
        'panicButton': _panicButton,
        'voiceCommand': _voiceCommand,
        'crashDetection': _crashDetection,
        'inactivity': _inactivity,
        'inactivityMinutes': _inactivityMinutes,
        'healthEmergency': _healthEmergency,
        'smartWatch': _smartWatch,
        'falseAlarmPrevention': _falseAlarmPrevention,
        'confirmationSeconds': _confirmationSeconds,
        'smsEnabled': _smsEnabled,
        'pushEnabled': _pushEnabled,
        'whatsappEnabled': _whatsappEnabled,
        'emailEnabled': _emailEnabled,
        'telegramEnabled': _telegramEnabled,
        'autoCall112': _autoCall112,
        'autoCallFamily': _autoCallFamily,
        'autoPlayMessage': _autoPlayMessage,
        'locationShare': _locationShare,
        'locationFrequency': _locationFrequency,
        'locationDuration': _locationDuration,
        'includeRoute': _includeRoute,
        'audioRecording': _audioRecording,
        'recordingDuration': _recordingDuration,
        'autoUpload': _autoUpload,
        'triggerWords': _triggerWords,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).sosAyarlari),
        actions: [
          // Not: "test" (science) ikonu KALDIRILDI — test SOS akışı yok,
          // buton tıklanıp hiçbir şey yapmıyordu. Acil durum ekranında
          // çalışmayan bir test butonu güven kırıcıdır.
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(AppLocalizations.of(context).tetikleyiciler, [
            _switch(
              'Panik butonu (3 sn basılı tut)',
              _panicButton,
              (v) => setState(() => _panicButton = v),
            ),
            _switch(
              'Sesli komut ("Yardım et")',
              _voiceCommand,
              (v) => setState(() => _voiceCommand = v),
            ),
            _switch(
              'Kaza tespiti (otomatik)',
              _crashDetection,
              (v) => setState(() => _crashDetection = v),
            ),
            _switch(
              'Uzun süre hareketsizlik',
              _inactivity,
              (v) => setState(() => _inactivity = v),
            ),
            if (_inactivity)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: _numField(
                  'Süre (dk)',
                  _inactivityMinutes.toString(),
                  (v) => _inactivityMinutes = int.tryParse(v) ?? 60,
                ),
              ),
            _switch(
              'Sağlık aciliyeti',
              _healthEmergency,
              (v) => setState(() => _healthEmergency = v),
            ),
            _switch(
              'Akıllı saat entegrasyonu',
              _smartWatch,
              (v) => setState(() => _smartWatch = v),
            ),
            _switch(
              'Yanlış alarm önleme',
              _falseAlarmPrevention,
              (v) => setState(() => _falseAlarmPrevention = v),
            ),
            if (_falseAlarmPrevention)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: _numField(
                  'Doğrulama (sn)',
                  _confirmationSeconds.toString(),
                  (v) => _confirmationSeconds = int.tryParse(v) ?? 5,
                ),
              ),
          ]),

          _section(AppLocalizations.of(context).otomatikMesajlar, [
            _switch(
              'SMS gönder',
              _smsEnabled,
              (v) => setState(() => _smsEnabled = v),
            ),
            _switch(
              'Push bildirimi',
              _pushEnabled,
              (v) => setState(() => _pushEnabled = v),
            ),
            _switch(
              'WhatsApp',
              _whatsappEnabled,
              (v) => setState(() => _whatsappEnabled = v),
            ),
            _switch(
              'E-posta',
              _emailEnabled,
              (v) => setState(() => _emailEnabled = v),
            ),
            _switch(
              'Telegram',
              _telegramEnabled,
              (v) => setState(() => _telegramEnabled = v),
            ),
          ]),

          _section(AppLocalizations.of(context).otomatikAramalar, [
            _switch(
              '112\'yi otomatik ara',
              _autoCall112,
              (v) => setState(() => _autoCall112 = v),
            ),
            if (_autoCall112)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(AppLocalizations.of(context).yasalUyariYanlisAramaCezasiKullaniciSorumlulugundadir,
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            _switch(
              'Aile üyelerini ara',
              _autoCallFamily,
              (v) => setState(() => _autoCallFamily = v),
            ),
            _switch(
              'Otomatik mesaj oku',
              _autoPlayMessage,
              (v) => setState(() => _autoPlayMessage = v),
            ),
          ]),

          _section(AppLocalizations.of(context).konumPaylasimi, [
            _switch(
              'Anlık konum paylaş',
              _locationShare,
              (v) => setState(() => _locationShare = v),
            ),
            if (_locationShare) ...[
              _numField(
                'Sıklık (sn)',
                _locationFrequency.toString(),
                (v) => _locationFrequency = int.tryParse(v) ?? 30,
              ),
              _numField(
                'Süre (dk, 0=süresiz)',
                _locationDuration.toString(),
                (v) => _locationDuration = int.tryParse(v) ?? 30,
              ),
              SwitchListTile(
                value: _includeRoute,
                onChanged: (v) => setState(() => _includeRoute = v),
                title: Text(AppLocalizations.of(context).rotaGecmisiniEkle),
                dense: true,
              ),
            ],
          ]),

          _section('SES KAYDI', [
            _switch(
              'Otomatik ses kaydı',
              _audioRecording,
              (v) => setState(() => _audioRecording = v),
            ),
            if (_audioRecording) ...[
              _numField(
                'Süre (dk)',
                _recordingDuration.toString(),
                (v) => _recordingDuration = int.tryParse(v) ?? 5,
              ),
              SwitchListTile(
                value: _autoUpload,
                onChanged: (v) => setState(() => _autoUpload = v),
                title: Text(AppLocalizations.of(context).bulutaYukle),
                dense: true,
              ),
              SwitchListTile(
                value: _triggerWords,
                onChanged: (v) => setState(() => _triggerWords = v),
                title: Text(AppLocalizations.of(context).sosTriggerWord),
                dense: true,
              ),
            ],
          ]),

          // Yükseltme zinciri: adımlar YUKARIDAKİ ayarlardan türetilir
          // (düzenlenebilir liste değil). Önceden hardcoded 4 adım + çalışmayan
          // "Adım Ekle/Düzenle/Sil" butonları vardı; kullanıcı acil durumda
          // işleyeceğini sandığı bir zinciri yapılandırdığını sanıyordu.
          _section(AppLocalizations.of(context).yukseltmeZinciri, [
            _escalationStep('1. [0 dk] Aile bildirimi', _autoCallFamily),
            _escalationStep('2. [3 dk] Acil kontaklar', _smsEnabled),
            _escalationStep('3. [5 dk] 112 arama', _autoCall112),
            _escalationStep('4. [anlık] Konum paylaşımı', _locationShare),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).sosEscalationNote,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ]),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(AppLocalizations.of(context).crashSaveUpper, style: const TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      dense: true,
    );
  }

  Widget _numField(
    String label,
    String initial,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: initial),
      onChanged: onChanged,
    );
  }

  Widget _escalationStep(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_box : Icons.check_box_outline_blank,
            color: enabled ? Colors.green : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(204),
                fontSize: 13,
              ),
            ),
          ),
          // Not: "Düzenle/Sil" butonları KALDIRILDI — adımlar sabit değil,
          // yukarıdaki ayarlardan türetiliyor; butonlar hiçbir şey yapmıyordu.
        ],
      ),
    );
  }

  /// Ayarları GERÇEKTEN kaydeder.
  ///
  /// Önceden yalnızca "kaydedildi" mesajı gösteriliyordu; hiçbir ayar
  /// saklanmıyordu. Acil durum modülünde bu kritik bir sahte başarıydı —
  /// kullanıcı panik butonu/tetikleyici tercihlerinin geçerli olduğunu
  /// sanıyordu ama ekran her açılışta varsayılana dönüyordu.
  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final okMsg = AppLocalizations.of(context).sosAyarlariKaydedildi;
    final failMsg = AppLocalizations.of(context).sosSettingsSaveFailed;
    try {
      await HiveService.setSetting(_settingsKey, jsonEncode(_toJson()));
      messenger.showSnackBar(SnackBar(content: Text(okMsg)));
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'emergency', operation: 'saveSosSettings', stackTrace: st);
      messenger.showSnackBar(SnackBar(
        content: Text(failMsg),
        backgroundColor: const Color(0xFFB42318),
      ));
    }
  }
}
