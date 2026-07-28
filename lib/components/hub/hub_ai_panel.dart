import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../core/app_logger.dart';
import '../../services/ai/ai_engine.dart';
import '../../features/familyhub_ai/domain/ai_action.dart';
import '../../features/familyhub_ai/domain/ai_action_parser.dart';
import '../../features/familyhub_ai/application/ai_action_executor.dart';

/// Hub'da gömülü kompakt AI sohbet paneli.
/// Kullanıcı soru sorar veya İŞLEM ister; model structured action döndürürse
/// (FH-04) doğrulanır, riskliyse onay istenir, executor GERÇEK repository
/// çağrısı yapar ve sonuç backend'e göre bildirilir — sahte başarı YOK.
class HubAiPanel extends ConsumerStatefulWidget {
  const HubAiPanel({super.key});

  @override
  ConsumerState<HubAiPanel> createState() => _HubAiPanelState();
}

class _HubAiPanelState extends ConsumerState<HubAiPanel> {
  final _input = TextEditingController();
  String? _answer;
  bool _loading = false;
  // Idempotency: aynı mesaj işlenirken ikinci kez çalıştırılmaz (§8 duplicate).
  String? _inFlightKey;

  static const _systemPrompt =
      'Sen FamilyHub aile uygulamasının yardımcı yapay zekâsısın. Türkçe, kısa '
      've pratik yanıt ver (en fazla 4-5 cümle). Aile, çocuk gelişimi, mutfak/'
      'tarif, bütçe/gider, planlama ve organizasyon konularında yardımcı ol. '
      'Teşhis koyma; sağlık konusunda gerekiyorsa uzmana danışmayı öner.\n\n'
      'KULLANICI BİR İŞLEM İSTERSE (liste/görev/hatırlatma/etkinlik), SADECE '
      'şu JSON formatında yanıt ver:\n'
      '{"reply":"kısa açıklama","action":{"type":"<tür>","payload":{...}}}\n'
      'İzinli türler ve payload:\n'
      '- addShoppingItems: {"items":["süt","ekmek"]}\n'
      '- createReminder: {"title":"...","days":1}\n'
      '- createTask: {"title":"...","description":"..."}\n'
      '- createCalendarEvent: {"title":"...","date":"2026-07-24T15:30:00"}\n'
      'ASLA family_id/user_id/child_id gönderme. İşlem istenmiyorsa düz metin '
      'yanıt ver (JSON kullanma).';

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
    // §8 idempotency: aynı mesaj işlenirken tekrar çalıştırma (double-submit).
    if (_inFlightKey == q) return;
    _inFlightKey = q;
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

      // FH-04: structured action varsa doğrula → onayla → GERÇEKTEN çalıştır.
      final parsed = parseAiResponse(res.content);
      final action = parsed.action;
      if (action == null) {
        setState(() {
          _answer = _prettify(parsed.reply);
          _loading = false;
        });
        return;
      }

      // Riskli aksiyonlarda runtime onayı (silme/görev/hatırlatma/etkinlik).
      if (action.requiresConfirmation) {
        final ok = await _confirmAction(action, parsed.reply);
        if (!mounted) return;
        if (ok != true) {
          setState(() {
            _answer = parsed.reply;
            _loading = false;
          });
          return;
        }
      }

      final result =
          await const AIActionExecutor().execute(action, ref, context);
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      // Sonuç GERÇEK backend dönüşüne göre — sahte "tamamlandı" YOK (§4.4).
      final msg = switch (result) {
        AIExecResult.done => '${parsed.reply}\n\n✅ ${t.aiActionDone}',
        AIExecResult.failed => '⚠️ ${t.aiActionFailed}',
        AIExecResult.invalid => '⚠️ ${t.aiActionInvalid}',
        AIExecResult.unsupported => parsed.reply,
      };
      setState(() {
        _answer = msg;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'ai', operation: 'hubPanelAsk', stackTrace: st);
      if (!mounted) return;
      setState(() {
        _answer = 'Şu an yanıt veremedim. Lütfen tekrar deneyin.';
        _loading = false;
      });
    } finally {
      _inFlightKey = null;
    }
  }

  /// Aksiyon önizlemesi + onay (kritik işlem onaysız yapılmaz).
  Future<bool?> _confirmAction(AIAction action, String reply) {
    final t = AppLocalizations.of(context);
    final items = action.payload['items'];
    final title = action.payload['title']?.toString();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        title: Text(t.aiActionConfirmTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reply,
                style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13)),
            const SizedBox(height: 10),
            if (title != null)
              Text('• $title',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            if (items is List)
              ...items.map((e) => Text('• $e',
                  style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.aiActionConfirm,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
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
      } catch (e) {
        // Best-effort: biçimlendirme başarısızsa aşağıdaki düz metne düşer.
        AppLogger.logBestEffort(e, module: 'ai', operation: 'formatSuggestions');
      }
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
              Expanded(
                child: Text(AppLocalizations.of(context).familyHubAITitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.aiAssistant),
                child: Row(
                  children: [
                    Text(AppLocalizations.of(context).hapFullChat,
                        style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700)),
                    const Icon(Icons.chevron_right, color: Color(0xFF8B5CF6), size: 18),
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
                  ? Row(
                      children: [
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF8B5CF6))),
                        const SizedBox(width: 10),
                        Text(AppLocalizations.of(context).hapThinking,
                            style: const TextStyle(color: Color(0xFF9CA3AF))),
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
                    hintText: AppLocalizations.of(context).hapAskHint,
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
