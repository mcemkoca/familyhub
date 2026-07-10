// lib/presentation/screens/emergency/sos_settings_screen.dart
// SOS settings: triggers, messages, calls, location, audio, escalation chain

import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).sosAyarlari),
        actions: [
          IconButton(icon: const Icon(Icons.science), onPressed: () {}),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('TETİKLEYİCİLER', [
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

          _section('OTOMATİK MESAJLAR', [
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

          _section('OTOMATİK ARAMALAR', [
            _switch(
              '112\'yi otomatik ara',
              _autoCall112,
              (v) => setState(() => _autoCall112 = v),
            ),
            if (_autoCall112)
              Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8),
                child: Text(AppLocalizations.of(context).yasalUyariYanlisAramaCezasiKullaniciSorumlulugundadir,
                  style: TextStyle(color: Colors.orange, fontSize: 12),
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

          _section('KONUM PAYLAŞIMI', [
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
                title: const Text('Trigger word analizi'),
                dense: true,
              ),
            ],
          ]),

          _section('YÜKSELTME ZİNCİRİ', [
            _escalationStep('1. [0 dk] Aile bildirimi', true),
            _escalationStep('2. [3 dk] Acil kontaklar', true),
            _escalationStep('3. [5 dk] 112 arama', false),
            _escalationStep('4. [10 dk] Komşu alert', false),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).adimEkle),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ]),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('KAYDET', style: TextStyle(fontSize: 16)),
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).sosAyarlariKaydedildi)));
  }
}
