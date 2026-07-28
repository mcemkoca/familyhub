import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/domain/entities.dart';

void main() {
  group('ShoppingUnit stable key', () {
    test('enum adı stable key olarak korunur', () {
      expect(ShoppingUnit.piece.name, 'piece');
      expect(ShoppingUnit.kilogram.name, 'kilogram');
      expect(ShoppingUnit.milliliter.name, 'milliliter');
    });

    test('shoppingUnitFromKey bilinen anahtarı çözer', () {
      expect(shoppingUnitFromKey('kilogram'), ShoppingUnit.kilogram);
      expect(shoppingUnitFromKey('bottle'), ShoppingUnit.bottle);
    });

    test('bilinmeyen/null anahtar piece fallback', () {
      expect(shoppingUnitFromKey(null), ShoppingUnit.piece);
      expect(shoppingUnitFromKey('kilogramme'), ShoppingUnit.piece);
      expect(shoppingUnitFromKey(''), ShoppingUnit.piece);
    });

    test('12 birim tanımlı', () {
      expect(ShoppingUnit.values.length, 12);
    });
  });

  group('ShoppingItem serialization', () {
    const item = ShoppingItem(
      id: 'local_1',
      name: 'Süt',
      quantity: '2',
      unit: ShoppingUnit.liter,
      category: ShoppingCategory.grocery,
      requestedBy: 'u1',
      isCompleted: false,
    );

    test('toJson unit stable key yazar', () {
      final json = item.toJson();
      expect(json['unit'], 'liter');
      expect(json['category'], ShoppingCategory.grocery.index);
    });

    test('round-trip veri kaybı yok', () {
      final back = ShoppingItem.fromJson(item.toJson());
      expect(back.id, item.id);
      expect(back.name, item.name);
      expect(back.quantity, item.quantity);
      expect(back.unit, item.unit);
      expect(back.category, item.category);
    });

    test('eski kayıt (unit alanı yok) → piece fallback (geriye uyum)', () {
      final legacy = {
        'id': 'x',
        'name': 'Ekmek',
        'quantity': '1',
        'category': ShoppingCategory.grocery.index,
        'requestedBy': 'u1',
        'isCompleted': false,
      };
      final item = ShoppingItem.fromJson(legacy);
      expect(item.unit, ShoppingUnit.piece);
      expect(item.name, 'Ekmek');
    });

    test('copyWith unit ve diğer alanları korur', () {
      final done = item.copyWith(isCompleted: true, completedBy: 'u2');
      expect(done.isCompleted, true);
      expect(done.completedBy, 'u2');
      expect(done.unit, ShoppingUnit.liter);
      expect(done.name, 'Süt');
    });

    test('copyWithUnit yalnızca birimi değiştirir', () {
      final changed = item.copyWithUnit(ShoppingUnit.pack);
      expect(changed.unit, ShoppingUnit.pack);
      expect(changed.quantity, item.quantity);
      expect(changed.name, item.name);
    });
  });

  group('Duplicate normalizasyonu (case-insensitive)', () {
    // Ekranın duplicate koruması ile aynı normalizasyon mantığı.
    String norm(String s) => s.trim().toLowerCase();

    test('büyük/küçük harf ve boşluk farkı aynı sayılır', () {
      expect(norm('Süt') == norm('süt'), true);
      expect(norm('  Ekmek ') == norm('ekmek'), true);
    });

    test('farklı ürünler ayrı sayılır', () {
      expect(norm('Tam Yağlı Süt') == norm('Süt'), false);
    });
  });
}
