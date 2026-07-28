import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/application/kitchen_memory_adapter.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';

/// Mutfak adapter'ı — tercih/alerji çıkarımı ve kanonik anahtarlar.
void main() {
  group('kanonik anahtarlar (dile bağımsız)', () {
    test('sevmeme anahtarı', () {
      expect(foodPreferenceKey(item: 'Mantar', liked: false),
          'food.disliked.mantar');
    });

    test('sevme anahtarı', () {
      expect(foodPreferenceKey(item: 'Brokoli', liked: true),
          'food.liked.brokoli');
    });

    test('Türkçe aksan normalize edilir', () {
      expect(foodAllergyKey('Yer Fıstığı'), 'food.allergy.yer_fistigi');
    });
  });

  group('alerji çıkarımı — kritik kısıt', () {
    test('KRİTİK: alerji restriction olarak çıkarılır', () {
      final c = extractKitchenCandidates(text: 'Fıstık alerjisi var');
      expect(c.length, 1);
      expect(c.single.kind, MemoryKind.restriction);
      expect(c.single.importance, greaterThan(0.9));
    });

    test('alerji sağlık hassasiyetinde sınıflanır', () {
      final c = extractKitchenCandidates(text: 'Fıstık alerjisi var');
      expect(c.single.sensitivity, MemorySensitivity.health);
    });

    test('KRİTİK: çocuk alerjisi minorData + childPrivate', () {
      final c =
          extractKitchenCandidates(text: 'Fıstık alerjisi var', childId: 'c1');
      expect(c.single.sensitivity, MemorySensitivity.minorData);
      expect(c.single.scope, MemoryScope.childPrivate);
    });

    test('alerji cümlesinden tercih çıkarılmaz (karışma yok)', () {
      final c = extractKitchenCandidates(text: 'Fıstık alerjisi var');
      expect(c.every((x) => x.kind == MemoryKind.restriction), isTrue);
    });
  });

  group('tercih çıkarımı', () {
    test('sevmeme tercihi çıkarılır', () {
      final c = extractKitchenCandidates(text: 'Mantar sevmiyorum');
      expect(c.single.kind, MemoryKind.preference);
      expect(c.single.key, 'food.disliked.mantar');
      expect(c.single.structuredData['preference'], 'dislike');
    });

    test('sevme tercihi çıkarılır', () {
      final c = extractKitchenCandidates(text: 'Brokoli seviyorum');
      expect(c.single.key, 'food.liked.brokoli');
      expect(c.single.structuredData['preference'], 'like');
    });

    test('çocuk tercihi childPrivate kapsamında', () {
      final c =
          extractKitchenCandidates(text: 'Brokoli seviyor', childId: 'c1');
      expect(c.single.scope, MemoryScope.childPrivate);
    });
  });

  group('TUTUCU davranış — emin değilse aday üretme', () {
    test('boş metin aday üretmez', () {
      expect(extractKitchenCandidates(text: '   '), isEmpty);
    });

    test('alakasız cümle aday üretmez', () {
      expect(extractKitchenCandidates(text: 'Bugün hava güzel'), isEmpty);
    });

    test('KRİTİK: zamirden yemek adı uydurulmaz', () {
      // "onu sevmiyorum" → hangi yemek belirsiz → kayıt YOK
      expect(extractKitchenCandidates(text: 'Onu sevmiyorum'), isEmpty);
    });

    test('işaretçi başta ise aday üretilmez', () {
      expect(extractKitchenCandidates(text: 'sevmiyorum'), isEmpty);
    });
  });

  group('olay üretimi', () {
    test('kitchen modülü ve kimlik alanları taşınır', () {
      final e = kitchenMemoryEvent(
        eventId: 'e1',
        sourceId: 'msg1',
        userId: 'u1',
        familyId: 'f1',
        childId: 'c1',
      );
      expect(e.module, 'kitchen');
      expect(e.userId, 'u1');
      expect(e.childId, 'c1');
    });
  });
}
