import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/context_memory/domain/memory_event.dart';
import 'package:familyhub/features/context_memory/domain/memory_policy.dart';
import 'package:familyhub/features/context_memory/domain/memory_prompt_composer.dart';
import 'package:familyhub/features/context_memory/infrastructure/memory_repository.dart';
import 'package:familyhub/services/hive_service.dart';

/// Context Memory Faz 7 — pipeline uçtan uca (gerçek Hive deposuyla).
///
/// Zincir: MemoryEvent → politika → dedup/çelişki → kalıcı kayıt →
/// retrieval → bağlam paketi → prompt.
void main() {
  setUpAll(() async {
    Hive.init('.dart_tool/test_hive_memory');
    await HiveService.init();
  });

  setUp(() async {
    // Her test temiz depo ile başlar.
    await MemoryRepository.instance.purgeUser('u1');
    await MemoryRepository.instance.purgeUser('u2');
  });

  MemoryEvent event({
    String id = 'e1',
    String? userId = 'u1',
    String? childId,
    bool remember = false,
  }) =>
      MemoryEvent(
        id: id,
        eventType: 'user_message',
        module: 'kitchen',
        sourceId: 'msg1',
        userId: userId,
        familyId: 'f1',
        childId: childId,
        occurredAt: DateTime.utc(2026, 7, 18),
        explicitRememberRequest: remember,
      );

  MemoryCandidate cand({
    String key = 'food.disliked.mushroom',
    String content = 'Mantar sevmiyor',
    MemorySensitivity sensitivity = MemorySensitivity.normal,
    MemorySourceType source = MemorySourceType.userMessage,
    MemoryScope scope = MemoryScope.userPrivate,
    double confidence = 1.0,
    String module = 'kitchen',
  }) =>
      MemoryCandidate(
        kind: MemoryKind.preference,
        scope: scope,
        sensitivity: sensitivity,
        sourceType: source,
        module: module,
        key: key,
        title: 'Tercih',
        content: content,
        confidence: confidence,
        explicit: true,
      );

  final ts = DateTime.utc(2026, 7, 18, 12);

  group('uçtan uca: kaydet → getir → prompt', () {
    test('tercih saklanır ve bağlama girer', () async {
      final svc = MemoryIngestionService();
      final res = await svc.ingest(event(), [cand()], now: ts);
      expect(res.accepted.length, 1);

      final packet = MemoryContextService().buildPacket(
        userId: 'u1',
        query: 'mantar',
        now: ts,
      );
      expect(packet.totalIncluded, 1);

      final prompt = composeSystemPrompt(basePrompt: 'BASE', packet: packet);
      expect(prompt, contains('Mantar sevmiyor'));
      expect(prompt, startsWith('BASE'));
    });

    test('KRİTİK: credential ASLA saklanmaz', () async {
      final svc = MemoryIngestionService();
      final res = await svc.ingest(
        event(),
        [cand(sensitivity: MemorySensitivity.credential, content: 'sifre 123')],
        now: ts,
      );
      expect(res.accepted, isEmpty);
      expect(res.rejected.values.first,
          'credential_or_prohibited_never_stored');
      expect(MemoryRepository.instance.recordsFor('u1'), isEmpty);
    });

    test('memory kapalıyken hiçbir şey saklanmaz', () async {
      final svc =
          MemoryIngestionService(consent: MemoryConsentSnapshot.disabled);
      final res = await svc.ingest(event(), [cand()], now: ts);
      expect(res.accepted, isEmpty);
      expect(MemoryRepository.instance.recordsFor('u1'), isEmpty);
    });

    test('hassas veri izinsiz saklanmaz, izinle saklanır', () async {
      final health = cand(
          key: 'health.allergy.peanut',
          content: 'Yer fıstığı alerjisi',
          sensitivity: MemorySensitivity.health,
          module: 'health');

      final denied = await MemoryIngestionService().ingest(
          event(id: 'e_denied'), [health],
          now: ts);
      expect(denied.accepted, isEmpty);

      final allowed = await MemoryIngestionService(
        consent: const MemoryConsentSnapshot(sensitiveMemoryEnabled: true),
      ).ingest(event(id: 'e_ok'), [health], now: ts);
      expect(allowed.accepted.length, 1);
    });
  });

  group('dedup ve çelişki (kalıcı)', () {
    test('aynı bilgi iki kez gelirse duplicate oluşmaz', () async {
      final svc = MemoryIngestionService();
      await svc.ingest(event(id: 'e1'), [cand()], now: ts);
      final second = await svc.ingest(event(id: 'e2'), [cand()], now: ts);

      expect(second.rejected['food.disliked.mushroom'], 'duplicate');
      expect(MemoryRepository.instance.recordsFor('u1').length, 1);
    });

    test('KULLANICI DÜZELTMESİ eski kaydı superseded yapar (silmez)', () async {
      final svc = MemoryIngestionService();
      await svc.ingest(event(id: 'e1'), [cand(content: 'Mantar sevmiyor')],
          now: ts);
      await svc.ingest(
        event(id: 'e2'),
        [
          cand(
              content: 'Aslında mantar seviyor',
              source: MemorySourceType.userCorrection)
        ],
        now: ts.add(const Duration(minutes: 1)),
      );

      final all = MemoryRepository.instance.recordsFor('u1');
      expect(all.length, 2); // eski SİLİNMEDİ
      expect(all.where((r) => r.status == MemoryStatus.superseded).length, 1);
      expect(all.where((r) => r.status == MemoryStatus.active).length, 1);

      // Bağlamda YALNIZCA güncel bilgi görünür.
      final packet = MemoryContextService()
          .buildPacket(userId: 'u1', query: 'mantar', now: ts);
      expect(packet.totalIncluded, 1);
      final prompt = composeSystemPrompt(basePrompt: 'B', packet: packet);
      expect(prompt, contains('Aslında mantar seviyor'));
      expect(prompt.contains('Mantar sevmiyor'), isFalse);
    });

    test('AI çıkarımı kullanıcı beyanını ezemez → disputed, bağlama girmez',
        () async {
      final svc = MemoryIngestionService();
      await svc.ingest(event(id: 'e1'), [cand(content: 'Mantar sevmiyor')],
          now: ts);
      await svc.ingest(
        event(id: 'e2'),
        [
          cand(
              content: 'Muhtemelen mantar seviyor',
              source: MemorySourceType.aiDerived)
        ],
        now: ts.add(const Duration(minutes: 1)),
      );

      final all = MemoryRepository.instance.recordsFor('u1');
      expect(all.where((r) => r.status == MemoryStatus.disputed).length, 1);

      // Çelişkili kayıt kesin bilgi olarak sunulmaz.
      final packet = MemoryContextService()
          .buildPacket(userId: 'u1', query: 'mantar', now: ts);
      expect(packet.confirmedFacts.any((r) => r.content.contains('Muhtemelen')),
          isFalse);
    });
  });

  group('KULLANICI İZOLASYONU (kalıcı depo)', () {
    test('KRİTİK: kullanıcı A kaydı kullanıcı B bağlamına girmez', () async {
      await MemoryIngestionService()
          .ingest(event(id: 'e1', userId: 'u1'), [cand()], now: ts);

      final bPacket = MemoryContextService()
          .buildPacket(userId: 'u2', query: 'mantar', now: ts);
      expect(bPacket.isEmpty, isTrue);
      expect(MemoryRepository.instance.recordsFor('u2'), isEmpty);
    });

    test('purgeUser yalnızca o kullanıcıyı siler', () async {
      await MemoryIngestionService()
          .ingest(event(id: 'e1', userId: 'u1'), [cand()], now: ts);
      await MemoryIngestionService()
          .ingest(event(id: 'e2', userId: 'u2'), [cand()], now: ts);

      final removed = await MemoryRepository.instance.purgeUser('u1');
      expect(removed, 1);
      expect(MemoryRepository.instance.recordsFor('u1'), isEmpty);
      expect(MemoryRepository.instance.recordsFor('u2').length, 1);
    });
  });

  group('"bunu unut"', () {
    test('kendi kaydını siler ve bağlamdan çıkar', () async {
      final svc = MemoryIngestionService();
      await svc.ingest(event(), [cand()], now: ts);

      final n = await svc.forget(userId: 'u1', query: 'mantar', now: ts);
      expect(n, 1);

      final packet = MemoryContextService()
          .buildPacket(userId: 'u1', query: 'mantar', now: ts);
      expect(packet.isEmpty, isTrue);
    });

    test('KRİTİK: başkasının kaydını silemez', () async {
      await MemoryIngestionService()
          .ingest(event(id: 'e1', userId: 'u2'), [cand()], now: ts);

      final n = await MemoryIngestionService()
          .forget(userId: 'u1', query: 'mantar', now: ts);
      expect(n, 0);
      expect(MemoryRepository.instance.recordsFor('u2').length, 1);
    });
  });

  group('bağlam yoksa davranış değişmez', () {
    test('hiç kayıt yokken prompt temel talimatla aynı', () {
      final packet = MemoryContextService()
          .buildPacket(userId: 'u1', query: 'herhangi', now: ts);
      expect(composeSystemPrompt(basePrompt: 'BASE', packet: packet), 'BASE');
    });
  });
}
