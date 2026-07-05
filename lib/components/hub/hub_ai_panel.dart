import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../services/ai/ai_engine.dart';

/// Hub'da gömülü kompakt AI sohbet paneli.
/// Kullanıcı hızlıca soru sorar; Gemini (AIEngine) yanıtlar. Tam sohbet için
/// AI Asistan ekranına yönlendirir.
class HubAiPanel extends StatefulWidget {
  const HubAiPanel({super.key});

  @override
  State<HubAiPanel> createState() => _HubAiPanelState();
}

class _HubAiPanelState extends State<HubAiPanel> {
  final _input = TextEditingController();
  String? _answer;
  bool _loading = false;

  static const _systemPrompt =
      'Sen FamilyHub aile uygulamasının yardımcı yapay zekâsısın. Türkçe, kısa '
      've pratik yanıt ver (en fazla 4-5 cümle). Aile, çocuk gelişimi, mutfak/'
      'tarif, bütçe/gider, planlama ve organizasyon konularında yardımcı ol. '
      'Uygun olduğunda kullanıcıya uygulamadaki ilgili bölümü öner. Teşhis '
      'koyma; sağlık konusunda gerekiyorsa uzmana danışmayı öner.';

  static const _chips = [
    'Bugün ne pişirsem?',
    'Bu ay bütçemi nasıl düzenlerim?',
    'Çocuğuma 10 dk\'lık etkinlik öner',
    'Bu hafta ne planlamalıyım?',
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _ask([String? preset]) async {
    final q = (preset ?? _input.text).trim();
    if (q.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _answer = null;
      _input.text = q;
    });
    try {
      final res = await AIEngine.generate(
        prompt: q,
        systemPrompt: _systemPrompt,
        maxTokens: 500,
        temperature: 0.6,
      );
      if (!mounted) return;
      setState(() {
        _answer = _prettify(res.content);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _answer = 'Şu an yanıt veremedim. Lütfen tekrar deneyin.';
        _loading = false;
      });
    }
  }

  // Yanıt JSON (öneri fallback'i) ise okunaklı metne çevirir.
  String _prettify(String raw) {
    final t = raw.trim();
    if (t.startsWith('{') || t.startsWith('[')) {
      try {
        final decoded = jsonDecode(t);
        final list =
            (decoded is Map ? decoded['suggestions'] : decoded) as List?;
        if (list != null && list.isNotEmpty) {
          return list.map((s) {
            if (s is Map) {
              final title = s['title'] ?? '';
              final desc = s['description'] ?? '';
              return '• $title${desc.toString().isNotEmpty ? ' — $desc' : ''}';
            }
            return '• $s';
          }).join('\n');
        }
      } catch (_) {}
      return 'Öneriler hazır — ilgili bölümden inceleyebilirsin.';
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1330), Color(0xFF14122B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x338B5CF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('FamilyHub AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.aiAssistant),
                child: const Row(
                  children: [
                    Text('Tam sohbet',
                        style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right, color: Color(0xFF8B5CF6), size: 18),
                  ],
                ),
              ),
            ],
          ),
          // Yanıt / durum alanı
          if (_loading || _answer != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0B1C),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _loading
                  ? const Row(
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF8B5CF6))),
                        SizedBox(width: 10),
                        Text('Düşünüyor…',
                            style: TextStyle(color: Color(0xFF9CA3AF))),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Text(_answer ?? '',
                          style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 13.5,
                              height: 1.5)),
                    ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chips
                  .map((c) => GestureDetector(
                        onTap: () => _ask(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF221A3A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x338B5CF6)),
                          ),
                          child: Text(c,
                              style: const TextStyle(
                                  color: Color(0xFFC7D2FE),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _ask(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'FamilyHub AI\'ya sor…',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: const Color(0xFF0E0B1C),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _ask,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
