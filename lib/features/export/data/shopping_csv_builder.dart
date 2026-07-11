import '../../../domain/entities.dart';
import 'csv_exporter.dart';

/// Alışveriş listesini CSV'ye çevirir (saf; başlıklar dışarıdan lokalize gelir).
class ShoppingCsvBuilder {
  const ShoppingCsvBuilder._();

  /// [headers] sırası: [ürün, miktar, birim, kategori, tamamlandı].
  static String build(List<ShoppingItem> items, List<String> headers,
      {required String yes, required String no}) {
    final rows = items
        .map((i) => <String>[
              i.name,
              i.quantity ?? '',
              i.unit.name,
              i.category.name,
              i.isCompleted ? yes : no,
            ])
        .toList();
    return CsvExporter.encode(headers, rows);
  }
}
