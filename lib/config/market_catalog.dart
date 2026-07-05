/// Market kataloğu — ülkeye göre marketler + kategorili ürünler.
/// Gerçek fiyat API'si olmadığından fiyatlar ortalama; katalog HAFTALIK olarak
/// deterministik biçimde döner ("bu haftanın fırsatları").
class MarketProduct {
  final String emoji;
  final String name;
  final double price; // ortalama birim fiyat (yerel para)
  final String category;
  const MarketProduct(this.emoji, this.name, this.price, this.category);
}

class MarketCatalog {
  MarketCatalog._();

  /// Ülkeye göre marketler (BIM/A101 hariç).
  static const Map<String, List<String>> markets = {
    'BE': ['Aldi', 'Lidl', 'Colruyt', 'Carrefour', 'Delhaize'],
    'NL': ['Albert Heijn', 'Jumbo', 'Aldi', 'Lidl', 'Plus'],
    'FR': ['Carrefour', 'Leclerc', 'Auchan', 'Aldi', 'Lidl'],
    'DE': ['Aldi', 'Lidl', 'Rewe', 'Edeka', 'Kaufland'],
    'TR': ['Migros', 'CarrefourSA', 'Şok', 'Metro', 'Macrocenter'],
  };

  /// Para birimi çarpanı (BE/NL/FR/DE € bazlı; TR yaklaşık ₺).
  static double _priceFor(String country, double eur) {
    return country == 'TR' ? (eur * 35).roundToDouble() : eur;
  }

  static List<String> marketsFor(String country) =>
      markets[country] ?? markets['BE']!;

  /// Kategorili ürün kataloğu (temel EUR fiyatlarla).
  static const List<MarketProduct> _base = [
    // Meyve & Sebze
    MarketProduct('🍅', 'Domates', 2.2, 'Meyve & Sebze'),
    MarketProduct('🥒', 'Salatalık', 1.5, 'Meyve & Sebze'),
    MarketProduct('🧅', 'Soğan', 1.2, 'Meyve & Sebze'),
    MarketProduct('🥔', 'Patates', 1.8, 'Meyve & Sebze'),
    MarketProduct('🍌', 'Muz', 1.6, 'Meyve & Sebze'),
    MarketProduct('🍎', 'Elma', 2.0, 'Meyve & Sebze'),
    MarketProduct('🥬', 'Marul', 1.3, 'Meyve & Sebze'),
    MarketProduct('🫑', 'Biber', 2.4, 'Meyve & Sebze'),
    // Süt Ürünleri
    MarketProduct('🥛', 'Süt (1L)', 1.1, 'Süt Ürünleri'),
    MarketProduct('🧀', 'Kaşar Peyniri', 5.5, 'Süt Ürünleri'),
    MarketProduct('🧈', 'Tereyağı', 3.2, 'Süt Ürünleri'),
    MarketProduct('🥚', 'Yumurta (10lu)', 2.8, 'Süt Ürünleri'),
    MarketProduct('🍶', 'Yoğurt', 1.9, 'Süt Ürünleri'),
    // Et & Tavuk
    MarketProduct('🍗', 'Tavuk But', 6.5, 'Et & Tavuk'),
    MarketProduct('🥩', 'Kıyma (500g)', 7.5, 'Et & Tavuk'),
    MarketProduct('🍖', 'Kuzu Pirzola', 12.0, 'Et & Tavuk'),
    MarketProduct('🐟', 'Somon Fileto', 9.0, 'Et & Tavuk'),
    // Kahvaltılık
    MarketProduct('🍞', 'Ekmek', 1.2, 'Kahvaltılık'),
    MarketProduct('🫙', 'Bal', 6.0, 'Kahvaltılık'),
    MarketProduct('🍫', 'Kakaolu Krema', 3.5, 'Kahvaltılık'),
    MarketProduct('🫒', 'Zeytin', 4.0, 'Kahvaltılık'),
    MarketProduct('🧃', 'Meyve Suyu', 1.8, 'Kahvaltılık'),
    // Temel Gıda
    MarketProduct('🍚', 'Pirinç (1kg)', 2.5, 'Temel Gıda'),
    MarketProduct('🌾', 'Bulgur', 2.0, 'Temel Gıda'),
    MarketProduct('🍝', 'Makarna', 1.4, 'Temel Gıda'),
    MarketProduct('🫘', 'Kuru Fasulye', 2.6, 'Temel Gıda'),
    MarketProduct('🛢️', 'Ayçiçek Yağı', 4.5, 'Temel Gıda'),
    MarketProduct('🧂', 'Tuz', 0.8, 'Temel Gıda'),
    // Temizlik & Kağıt
    MarketProduct('🧴', 'Bulaşık Deterjanı', 2.9, 'Temizlik'),
    MarketProduct('🧻', 'Tuvalet Kağıdı', 4.5, 'Temizlik'),
    MarketProduct('🧼', 'Sabun', 1.5, 'Temizlik'),
    MarketProduct('🧺', 'Çamaşır Deterjanı', 6.5, 'Temizlik'),
    // Atıştırmalık & İçecek
    MarketProduct('🍪', 'Bisküvi', 1.6, 'Atıştırmalık'),
    MarketProduct('🥤', 'Kola (1.5L)', 1.9, 'Atıştırmalık'),
    MarketProduct('💧', 'Su (6x1.5L)', 2.4, 'Atıştırmalık'),
    MarketProduct('☕', 'Kahve', 5.0, 'Atıştırmalık'),
    MarketProduct('🍵', 'Çay', 4.0, 'Atıştırmalık'),
  ];

  static List<String> get categories =>
      _base.map((p) => p.category).toSet().toList();

  static List<MarketProduct> productsFor(String country, {String? category}) {
    return _base
        .where((p) => category == null || p.category == category)
        .map((p) => MarketProduct(
            p.emoji, p.name, _priceFor(country, p.price), p.category))
        .toList();
  }

  /// ISO hafta numarası — haftalık deterministik rotasyon için.
  static int weekNumber(DateTime d) {
    final firstDay = DateTime(d.year, 1, 1);
    final days = d.difference(firstDay).inDays;
    return ((days + firstDay.weekday) / 7).ceil();
  }

  /// Bu haftanın "fırsat" ürünleri — hafta numarasına göre döner.
  static List<MarketProduct> weeklyDeals(String country, {int count = 6}) {
    final all = productsFor(country);
    final wk = weekNumber(DateTime.now());
    final start = (wk * 3) % all.length;
    final deals = <MarketProduct>[];
    for (int i = 0; i < count; i++) {
      deals.add(all[(start + i * 5) % all.length]);
    }
    return deals;
  }

  /// Haftanın pazartesisi (güncelleme tarihi etiketi için).
  static DateTime weekMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }
}
