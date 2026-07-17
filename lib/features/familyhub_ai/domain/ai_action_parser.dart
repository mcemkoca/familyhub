/// AI ham çıktısından GÜVENLİ aksiyon çıkarımı (FH-04 / spec §8).
///
/// Model çıktısı GÜVENİLMEZ input kabul edilir:
///  - Bilinmeyen action type → aksiyon üretilmez (yalnızca metin).
///  - Şema doğrulaması (AIActionPolicy.isValid) geçmezse aksiyon düşürülür.
///  - Yalnızca tür-bazlı ALLOWLIST alanlar payload'a alınır; fazlalık temizlenir.
///  - family_id / user_id / child_id modelden ASLA alınmaz — bunlar aktif
///    session ve merkezi context üzerinden executor tarafında çözülür.
library;

import 'dart:convert';
import 'ai_action.dart';

/// Parse sonucu: kullanıcıya gösterilecek metin + (varsa) doğrulanmış aksiyon.
class AiActionParseResult {
  final String reply;
  final AIAction? action;
  const AiActionParseResult({required this.reply, this.action});
}

/// Modelden ASLA kabul edilmeyen alanlar (kimlik/yetki enjeksiyonu koruması).
const _forbiddenKeys = {
  'family_id', 'familyId', 'user_id', 'userId', 'child_id', 'childId',
  'role', 'permissions', 'token', 'auth',
};

/// Tür bazlı izinli payload alanları (fazlası atılır).
const _allowedKeys = <AIActionType, Set<String>>{
  AIActionType.addShoppingItems: {'items'},
  AIActionType.createReminder: {'title', 'body', 'days'},
  AIActionType.createTask: {'title', 'description', 'assignedTo', 'priority'},
  AIActionType.createCalendarEvent: {'title', 'date', 'description'},
  AIActionType.openLegalBenefit: {'url'},
  AIActionType.openModule: {},
  AIActionType.openEntity: {},
  AIActionType.summarizeBudget: {},
};

/// Ham metinden ilk JSON objesini ayıklar (``` çitleri ve serbest metin arası).
String? _extractJson(String raw) {
  final s = raw.trim();
  final start = s.indexOf('{');
  final end = s.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  return s.substring(start, end + 1);
}

/// AI yanıtını çözümler. Aksiyon yoksa/geçersizse yalnızca metin döner
/// (normal sohbet fallback'i — spec §8 test 13).
AiActionParseResult parseAiResponse(String raw) {
  final jsonStr = _extractJson(raw);
  if (jsonStr == null) {
    return AiActionParseResult(reply: raw.trim());
  }

  Object? decoded;
  try {
    decoded = jsonDecode(jsonStr);
  } catch (_) {
    // Bozuk JSON → aksiyon YOK, ham metin gösterilir (fail-safe).
    return AiActionParseResult(reply: raw.trim());
  }
  if (decoded is! Map) return AiActionParseResult(reply: raw.trim());

  final reply = (decoded['reply'] ?? decoded['text'] ?? '').toString().trim();
  final safeReply = reply.isEmpty ? raw.trim() : reply;

  final actionRaw = decoded['action'];
  if (actionRaw is! Map) return AiActionParseResult(reply: safeReply);

  // Bilinmeyen/izinsiz tür → aksiyon üretilmez.
  final type = AIActionPolicy.typeFromKey(actionRaw['type']?.toString());
  if (type == null) return AiActionParseResult(reply: safeReply);

  // Payload'ı allowlist'e göre temizle; yasaklı kimlik alanlarını at.
  final rawPayload = actionRaw['payload'];
  final allowed = _allowedKeys[type] ?? const <String>{};
  final payload = <String, Object?>{};
  if (rawPayload is Map) {
    rawPayload.forEach((k, v) {
      final key = k.toString();
      if (_forbiddenKeys.contains(key)) return; // kimlik enjeksiyonu engeli
      if (allowed.contains(key)) payload[key] = v;
    });
  }

  // route yalnızca uygulama-içi mutlak yol olabilir (açık yönlendirme engeli).
  final routeRaw = actionRaw['route']?.toString();
  final route =
      (routeRaw != null && routeRaw.startsWith('/')) ? routeRaw : null;

  final action = AIAction(type: type, route: route, payload: payload);

  // Şema doğrulaması — geçmezse aksiyon DÜŞÜRÜLÜR, metin kalır.
  if (!AIActionPolicy.isValid(action)) {
    return AiActionParseResult(reply: safeReply);
  }
  return AiActionParseResult(reply: safeReply, action: action);
}
