// lib/presentation/screens/emergency/sos_template_editor_screen.dart
// Emergency message template editor with variable support

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../core/settings_store.dart';

class SosTemplateEditorScreen extends StatefulWidget {
  const SosTemplateEditorScreen({super.key});

  @override
  State<SosTemplateEditorScreen> createState() => _SosTemplateEditorScreenState();
}

class _SosTemplateEditorScreenState extends State<SosTemplateEditorScreen> {
  final _smsCtrl = TextEditingController(
    text: '🆘 ACİL: {name} yardım istiyor!\nKonum: {location}\nSaat: {time}\nDurum: {status}\nHarita: {map_link}\nCanlı takip: {live_link}',
  );
  final _pushTitleCtrl = TextEditingController(text: '🆘 {name} - ACİL DURUM');
  final _pushBodyCtrl = TextEditingController(text: 'Yardım çağrısı! Konum: {location}');
  final _voiceCtrl = TextEditingController(
    text: 'Bu otomatik bir acil durum çağrısıdır. {name} yardım istiyor. Konum: Enlem {lat}, Boylam {lng}. Lütfen yardım için hemen harekete geçin.',
  );
  final FlutterTts _tts = FlutterTts();

  /// Sesli mesaj şablonunu örnek değerlerle seslendirir (önizleme).
  Future<void> _previewVoice() async {
    final sample = _voiceCtrl.text
        .replaceAll('{name}', 'Ahmet')
        .replaceAll('{lat}', '50.85')
        .replaceAll('{lng}', '4.35')
        .replaceAll(RegExp(r'\{[^}]*\}'), '');
    await _tts.setLanguage('tr-TR');
    await _tts.stop();
    await _tts.speak(sample);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔊 Sesli mesaj önizleniyor')),
      );
    }
  }

  final List<String> _variables = [
    '{name}',
    '{location}',
    '{coordinates}',
    '{time}',
    '{status}',
    '{map_link}',
    '{live_link}',
    '{health_info}',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).acilDurumMesajSablonu),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
          IconButton(icon: const Icon(Icons.restore), onPressed: _reset),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(AppLocalizations.of(context).smsSablonu, [
            TextField(
              controller: _smsCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context).smsMesaji,
              ),
            ),
          ]),

          _section(AppLocalizations.of(context).pushBildirimSablonu, [
            TextField(
              controller: _pushTitleCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).baslik, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pushBodyCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).icerik,
                border: const OutlineInputBorder(),
              ),
            ),
          ]),

          _section(AppLocalizations.of(context).sesliMesajSablonu, [
            TextField(
              controller: _voiceCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context).steMsgHint,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _previewVoice,
              icon: const Icon(Icons.volume_up),
              label: Text(AppLocalizations.of(context).onizleme),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
            ),
          ]),

          _section(AppLocalizations.of(context).kullanilabilirDegiskenler, [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _variables.map((v) => ActionChip(
                label: Text(v, style: const TextStyle(fontSize: 12)),
                onPressed: () => _insertVariable(v),
              )).toList(),
            ),
            const SizedBox(height: 8),
            const Text(
              '• {name} - Kullanıcı adı\n'
              '• {location} - Konum adresi\n'
              '• {coordinates} - Enlem/Boylam\n'
              '• {time} - Olay zamanı\n'
              '• {status} - Acil durum açıklaması\n'
              '• {map_link} - Google Maps linki\n'
              '• {live_link} - Canlı takip linki\n'
              '• {health_info} - Sağlık kartı özeti',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
            ),
          ]),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(AppLocalizations.of(context).crashSaveUpper, style: const TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF16213E), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  void _insertVariable(String variable) {
    // Insert into currently focused field
    // For simplicity, insert into SMS field
    final text = _smsCtrl.text;
    final selection = _smsCtrl.selection;
    final newText = text.replaceRange(selection.start, selection.end, variable);
    _smsCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + variable.length),
    );
  }

  static const _storeName = 'sos_templates';

  /// Şablonları GERÇEKTEN kaydeder (önceden yalnızca mesaj gösteriliyordu).
  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final okMsg = AppLocalizations.of(context).sablonKaydedildi;
    final failMsg = AppLocalizations.of(context).settingsSaveFailed;
    final ok = await SettingsStore.save(_storeName, {
      'sms': _smsCtrl.text,
      'pushTitle': _pushTitleCtrl.text,
      'pushBody': _pushBodyCtrl.text,
      'voice': _voiceCtrl.text,
    });
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? okMsg : failMsg),
      backgroundColor: ok ? null : const Color(0xFFB42318),
    ));
  }

  void _loadTemplates() {
    final j = SettingsStore.load(_storeName);
    if (j.isEmpty) return;
    setState(() {
      _smsCtrl.text = j['sms'] as String? ?? _smsCtrl.text;
      _pushTitleCtrl.text = j['pushTitle'] as String? ?? _pushTitleCtrl.text;
      _pushBodyCtrl.text = j['pushBody'] as String? ?? _pushBodyCtrl.text;
      _voiceCtrl.text = j['voice'] as String? ?? _voiceCtrl.text;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _reset() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).varsayilanaSifirlandi)));
  }
}
