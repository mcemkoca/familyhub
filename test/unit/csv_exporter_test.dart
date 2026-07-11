import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/domain/entities.dart';
import 'package:familyhub/features/export/data/csv_exporter.dart';
import 'package:familyhub/features/export/data/shopping_csv_builder.dart';

void main() {
  group('CsvExporter (RFC 4180 escape)', () {
    test('düz alanlar tırnaksız kodlanır', () {
      final csv = CsvExporter.encode(['a', 'b'], [
        ['1', '2'],
      ]);
      expect(csv, 'a,b\n1,2\n');
    });

    test('virgül içeren alan tırnaklanır', () {
      final csv = CsvExporter.encode(['x'], [
        ['elma, armut'],
      ]);
      expect(csv, 'x\n"elma, armut"\n');
    });

    test('çift tırnak ikiye katlanır', () {
      final csv = CsvExporter.encode(['x'], [
        ['20"'],
      ]);
      expect(csv, 'x\n"20"""\n');
    });

    test('satır sonu içeren alan tırnaklanır (injection/kırılma yok)', () {
      final csv = CsvExporter.encode(['x'], [
        ['a\nb'],
      ]);
      expect(csv, 'x\n"a\nb"\n');
    });
  });

  group('ShoppingCsvBuilder', () {
    test('öğeleri başlık + satırlara çevirir, tamamlandı evet/hayır', () {
      final items = [
        const ShoppingItem(
            id: '1',
            name: 'Süt',
            quantity: '2',
            unit: ShoppingUnit.liter,
            requestedBy: 'u1'),
        const ShoppingItem(
            id: '2', name: 'Ekmek', requestedBy: 'u1', isCompleted: true),
      ];
      final csv = ShoppingCsvBuilder.build(
        items,
        ['Ürün', 'Miktar', 'Birim', 'Kategori', 'Tamamlandı'],
        yes: 'Evet',
        no: 'Hayır',
      );
      final lines = csv.trim().split('\n');
      expect(lines.first, 'Ürün,Miktar,Birim,Kategori,Tamamlandı');
      expect(lines[1], startsWith('Süt,2,liter,'));
      expect(lines[1], endsWith(',Hayır'));
      expect(lines[2], endsWith(',Evet'));
    });

    test('virgüllü ürün adı güvenle escape edilir', () {
      final items = [
        const ShoppingItem(id: '1', name: 'Un, tam buğday', requestedBy: 'u1'),
      ];
      final csv = ShoppingCsvBuilder.build(
        items,
        ['Ürün', 'Miktar', 'Birim', 'Kategori', 'Tamamlandı'],
        yes: 'E',
        no: 'H',
      );
      expect(csv, contains('"Un, tam buğday"'));
    });
  });
}
