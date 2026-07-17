import 'dart:convert';

import '../services/hive_service.dart';
import '../core/app_logger.dart';

class MarketStore {
  final String id;
  final String name;
  final String onlineStoreUrl;

  const MarketStore(this.id, this.name, this.onlineStoreUrl);
}

class MarketProduct {
  final String id;
  final String emoji;
  final String name;
  final double price;
  final String category;
  final String currency;
  final String? sourceMarket;
  final String? sourceUrl;
  final DateTime? priceUpdatedAt;

  const MarketProduct({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
    required this.category,
    required this.currency,
    this.sourceMarket,
    this.sourceUrl,
    this.priceUpdatedAt,
  });

  bool get hasCurrentPrice => priceUpdatedAt != null;
}

class MarketPriceQuote {
  final String productId;
  final String country;
  final double price;
  final String currency;
  final String market;
  final String? sourceUrl;
  final DateTime retrievedAt;

  const MarketPriceQuote({
    required this.productId,
    required this.country,
    required this.price,
    required this.currency,
    required this.market,
    required this.retrievedAt,
    this.sourceUrl,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'country': country,
        'price': price,
        'currency': currency,
        'market': market,
        'source_url': sourceUrl,
        'retrieved_at': retrievedAt.toIso8601String(),
      };

  factory MarketPriceQuote.fromJson(Map<String, dynamic> json) {
    return MarketPriceQuote(
      productId: json['product_id'].toString(),
      country: json['country'].toString().toUpperCase(),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'].toString().toUpperCase(),
      market: json['market']?.toString() ?? 'online',
      sourceUrl: json['source_url']?.toString(),
      retrievedAt: DateTime.parse(json['retrieved_at'].toString()),
    );
  }
}

class _ProductSeed {
  final String id;
  final String emoji;
  final double fallbackEur;
  final String categoryId;
  const _ProductSeed(this.id, this.emoji, this.fallbackEur, this.categoryId);
}

/// Yerelleştirilmiş market kataloğu ve internet fiyat önbelleği.
///
/// Mağaza sayfaları mobil istemcide kazınmaz. Bir backend/AI/izinli sağlayıcıdan
/// gelen yapılandırılmış fiyatlar [saveQuotes] ile doğrulanıp Hive'a kaydedilir.
class MarketCatalog {
  MarketCatalog._();

  static const supportedLanguages = {'tr', 'en', 'fr', 'nl'};
  static const _quoteKey = 'market_price_quotes_v2';

  static const Map<String, List<MarketStore>> stores = {
    'BE': [
      MarketStore('aldi', 'Aldi', 'https://www.aldi.be/'),
      MarketStore('lidl', 'Lidl', 'https://www.lidl.be/'),
      MarketStore('colruyt', 'Colruyt', 'https://www.collectandgo.be/colruyt/'),
      MarketStore('carrefour', 'Carrefour', 'https://www.carrefour.be/'),
      MarketStore('delhaize', 'Delhaize', 'https://www.delhaize.be/shop/'),
    ],
    'NL': [
      MarketStore('ah', 'Albert Heijn', 'https://www.ah.nl/'),
      MarketStore('jumbo', 'Jumbo', 'https://www.jumbo.com/'),
      MarketStore('aldi', 'Aldi', 'https://www.aldi.nl/'),
      MarketStore('lidl', 'Lidl', 'https://www.lidl.nl/'),
      MarketStore('plus', 'Plus', 'https://www.plus.nl/'),
    ],
    'FR': [
      MarketStore('carrefour', 'Carrefour', 'https://www.carrefour.fr/'),
      MarketStore('leclerc', 'E.Leclerc', 'https://www.e.leclerc/'),
      MarketStore('auchan', 'Auchan', 'https://www.auchan.fr/'),
      MarketStore('aldi', 'Aldi', 'https://www.aldi.fr/'),
      MarketStore('lidl', 'Lidl', 'https://www.lidl.fr/'),
    ],
    'DE': [
      MarketStore('aldi', 'Aldi', 'https://www.aldi-nord.de/'),
      MarketStore('lidl', 'Lidl', 'https://www.lidl.de/'),
      MarketStore('rewe', 'Rewe', 'https://www.rewe.de/'),
      MarketStore('edeka', 'Edeka', 'https://www.edeka.de/'),
      MarketStore('kaufland', 'Kaufland', 'https://www.kaufland.de/'),
    ],
    'TR': [
      MarketStore('migros', 'Migros', 'https://www.migros.com.tr/'),
      MarketStore('carrefoursa', 'CarrefourSA', 'https://www.carrefoursa.com/'),
      MarketStore('sok', 'Şok', 'https://www.sokmarket.com.tr/'),
      MarketStore('metro', 'Metro', 'https://www.metro-tr.com/'),
      MarketStore('macrocenter', 'Macrocenter', 'https://www.macrocenter.com.tr/'),
    ],
  };

  static List<MarketStore> storesFor(String country) =>
      stores[country.toUpperCase()] ?? stores['BE']!;

  static List<String> marketsFor(String country) =>
      storesFor(country).map((s) => s.name).toList(growable: false);

  static const _categories = {
    'produce': {'tr': 'Meyve & Sebze', 'en': 'Fruit & Vegetables', 'fr': 'Fruits et légumes', 'nl': 'Groenten en fruit'},
    'dairy': {'tr': 'Süt Ürünleri', 'en': 'Dairy', 'fr': 'Produits laitiers', 'nl': 'Zuivel'},
    'meat': {'tr': 'Et & Tavuk', 'en': 'Meat & Poultry', 'fr': 'Viande et volaille', 'nl': 'Vlees en gevogelte'},
    'breakfast': {'tr': 'Kahvaltılık', 'en': 'Breakfast', 'fr': 'Petit-déjeuner', 'nl': 'Ontbijt'},
    'pantry': {'tr': 'Temel Gıda', 'en': 'Pantry staples', 'fr': 'Produits de base', 'nl': 'Basisvoeding'},
    'cleaning': {'tr': 'Temizlik', 'en': 'Cleaning', 'fr': 'Entretien', 'nl': 'Schoonmaak'},
    'snacks': {'tr': 'Atıştırmalık', 'en': 'Snacks & Drinks', 'fr': 'Snacks et boissons', 'nl': 'Snacks en dranken'},
  };

  static const _names = <String, Map<String, String>>{
    'tomato': {'tr':'Domates','en':'Tomatoes','fr':'Tomates','nl':'Tomaten'},
    'cucumber': {'tr':'Salatalık','en':'Cucumber','fr':'Concombre','nl':'Komkommer'},
    'onion': {'tr':'Soğan','en':'Onions','fr':'Oignons','nl':'Uien'},
    'potato': {'tr':'Patates','en':'Potatoes','fr':'Pommes de terre','nl':'Aardappelen'},
    'banana': {'tr':'Muz','en':'Bananas','fr':'Bananes','nl':'Bananen'},
    'apple': {'tr':'Elma','en':'Apples','fr':'Pommes','nl':'Appels'},
    'lettuce': {'tr':'Marul','en':'Lettuce','fr':'Laitue','nl':'Sla'},
    'pepper': {'tr':'Biber','en':'Bell peppers','fr':'Poivrons','nl':'Paprika'},
    'milk_1l': {'tr':'Süt (1 L)','en':'Milk (1 L)','fr':'Lait (1 L)','nl':'Melk (1 L)'},
    'cheese': {'tr':'Kaşar peyniri','en':'Cheese','fr':'Fromage','nl':'Kaas'},
    'butter': {'tr':'Tereyağı','en':'Butter','fr':'Beurre','nl':'Boter'},
    'eggs_10': {'tr':'Yumurta (10’lu)','en':'Eggs (10)','fr':'Œufs (10)','nl':'Eieren (10)'},
    'yogurt': {'tr':'Yoğurt','en':'Yogurt','fr':'Yaourt','nl':'Yoghurt'},
    'chicken_thigh': {'tr':'Tavuk but','en':'Chicken thighs','fr':'Cuisses de poulet','nl':'Kippendijen'},
    'minced_meat_500g': {'tr':'Kıyma (500 g)','en':'Minced meat (500 g)','fr':'Viande hachée (500 g)','nl':'Gehakt (500 g)'},
    'lamb_chops': {'tr':'Kuzu pirzola','en':'Lamb chops','fr':'Côtelettes d’agneau','nl':'Lamskoteletten'},
    'salmon_fillet': {'tr':'Somon fileto','en':'Salmon fillet','fr':'Filet de saumon','nl':'Zalmfilet'},
    'bread': {'tr':'Ekmek','en':'Bread','fr':'Pain','nl':'Brood'},
    'honey': {'tr':'Bal','en':'Honey','fr':'Miel','nl':'Honing'},
    'cocoa_spread': {'tr':'Kakaolu krema','en':'Chocolate spread','fr':'Pâte à tartiner','nl':'Chocopasta'},
    'olives': {'tr':'Zeytin','en':'Olives','fr':'Olives','nl':'Olijven'},
    'fruit_juice': {'tr':'Meyve suyu','en':'Fruit juice','fr':'Jus de fruits','nl':'Vruchtensap'},
    'rice_1kg': {'tr':'Pirinç (1 kg)','en':'Rice (1 kg)','fr':'Riz (1 kg)','nl':'Rijst (1 kg)'},
    'bulgur': {'tr':'Bulgur','en':'Bulgur','fr':'Boulgour','nl':'Bulgur'},
    'pasta': {'tr':'Makarna','en':'Pasta','fr':'Pâtes','nl':'Pasta'},
    'white_beans': {'tr':'Kuru fasulye','en':'White beans','fr':'Haricots blancs','nl':'Witte bonen'},
    'sunflower_oil': {'tr':'Ayçiçek yağı','en':'Sunflower oil','fr':'Huile de tournesol','nl':'Zonnebloemolie'},
    'salt': {'tr':'Tuz','en':'Salt','fr':'Sel','nl':'Zout'},
    'dish_soap': {'tr':'Bulaşık deterjanı','en':'Dishwashing liquid','fr':'Liquide vaisselle','nl':'Afwasmiddel'},
    'toilet_paper': {'tr':'Tuvalet kağıdı','en':'Toilet paper','fr':'Papier toilette','nl':'Toiletpapier'},
    'soap': {'tr':'Sabun','en':'Soap','fr':'Savon','nl':'Zeep'},
    'laundry_detergent': {'tr':'Çamaşır deterjanı','en':'Laundry detergent','fr':'Lessive','nl':'Wasmiddel'},
    'biscuits': {'tr':'Bisküvi','en':'Biscuits','fr':'Biscuits','nl':'Koekjes'},
    'cola_1_5l': {'tr':'Kola (1,5 L)','en':'Cola (1.5 L)','fr':'Cola (1,5 L)','nl':'Cola (1,5 L)'},
    'water_6x1_5l': {'tr':'Su (6 × 1,5 L)','en':'Water (6 × 1.5 L)','fr':'Eau (6 × 1,5 L)','nl':'Water (6 × 1,5 L)'},
    'coffee': {'tr':'Kahve','en':'Coffee','fr':'Café','nl':'Koffie'},
    'tea': {'tr':'Çay','en':'Tea','fr':'Thé','nl':'Thee'},
  };

  static const _base = <_ProductSeed>[
    _ProductSeed('tomato','🍅',2.2,'produce'), _ProductSeed('cucumber','🥒',1.5,'produce'),
    _ProductSeed('onion','🧅',1.2,'produce'), _ProductSeed('potato','🥔',1.8,'produce'),
    _ProductSeed('banana','🍌',1.6,'produce'), _ProductSeed('apple','🍎',2.0,'produce'),
    _ProductSeed('lettuce','🥬',1.3,'produce'), _ProductSeed('pepper','🫑',2.4,'produce'),
    _ProductSeed('milk_1l','🥛',1.1,'dairy'), _ProductSeed('cheese','🧀',5.5,'dairy'),
    _ProductSeed('butter','🧈',3.2,'dairy'), _ProductSeed('eggs_10','🥚',2.8,'dairy'),
    _ProductSeed('yogurt','🍶',1.9,'dairy'), _ProductSeed('chicken_thigh','🍗',6.5,'meat'),
    _ProductSeed('minced_meat_500g','🥩',7.5,'meat'), _ProductSeed('lamb_chops','🍖',12,'meat'),
    _ProductSeed('salmon_fillet','🐟',9,'meat'), _ProductSeed('bread','🍞',1.2,'breakfast'),
    _ProductSeed('honey','🫙',6,'breakfast'), _ProductSeed('cocoa_spread','🍫',3.5,'breakfast'),
    _ProductSeed('olives','🫒',4,'breakfast'), _ProductSeed('fruit_juice','🧃',1.8,'breakfast'),
    _ProductSeed('rice_1kg','🍚',2.5,'pantry'), _ProductSeed('bulgur','🌾',2,'pantry'),
    _ProductSeed('pasta','🍝',1.4,'pantry'), _ProductSeed('white_beans','🫘',2.6,'pantry'),
    _ProductSeed('sunflower_oil','🛢️',4.5,'pantry'), _ProductSeed('salt','🧂',.8,'pantry'),
    _ProductSeed('dish_soap','🧴',2.9,'cleaning'), _ProductSeed('toilet_paper','🧻',4.5,'cleaning'),
    _ProductSeed('soap','🧼',1.5,'cleaning'), _ProductSeed('laundry_detergent','🧺',6.5,'cleaning'),
    _ProductSeed('biscuits','🍪',1.6,'snacks'), _ProductSeed('cola_1_5l','🥤',1.9,'snacks'),
    _ProductSeed('water_6x1_5l','💧',2.4,'snacks'), _ProductSeed('coffee','☕',5,'snacks'),
    _ProductSeed('tea','🍵',4,'snacks'),
  ];

  static Map<String, MarketPriceQuote> _quotes = {};
  static DateTime? lastPriceUpdate;

  static String _language(String language) =>
      supportedLanguages.contains(language.toLowerCase()) ? language.toLowerCase() : 'en';
  static String _text(Map<String, String> values, String language) =>
      values[_language(language)] ?? values['en']!;
  static String _quoteId(String country, String productId) => '${country.toUpperCase()}:$productId';
  static String currencyFor(String country) => country.toUpperCase() == 'TR' ? 'TRY' : 'EUR';
  static String currencySymbolFor(String country) => country.toUpperCase() == 'TR' ? '₺' : '€';

  static List<String> categoriesFor(String language) =>
      _categories.values.map((v) => _text(v, language)).toList(growable: false);
  static List<String> categoryIds() => _categories.keys.toList(growable: false);
  static String categoryName(String id, String language) =>
      _text(_categories[id] ?? _categories['produce']!, language);

  /// Geriye dönük uyumluluk: varsayılan Türkçe kategoriler.
  static List<String> get categories => categoriesFor('tr');
  static List<String> get productNames => productNamesFor('tr');
  static List<String> productNamesFor(String language) =>
      _base.map((p) => _text(_names[p.id]!, language)).toList(growable: false);
  static List<Map<String, String>> productsForPriceRequest(String language) => _base
      .map((p) => {'id': p.id, 'name': _text(_names[p.id]!, language)})
      .toList(growable: false);

  static void loadOverrides() {
    _quotes = {};
    final raw = HiveService.getSetting(_quoteKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          final quote = MarketPriceQuote.fromJson(Map<String, dynamic>.from(item as Map));
          if (_isValidQuote(quote)) _quotes[_quoteId(quote.country, quote.productId)] = quote;
        }
      } catch (e) {
        // Best-effort: bozuk önbellek yok sayılır, katalog varsayılanları kullanılır.
        AppLogger.logBestEffort(e, module: 'content', operation: 'loadCachedQuotes');
      }
    }
    final ts = HiveService.getSetting('market_price_updated_at');
    if (ts != null) lastPriceUpdate = DateTime.tryParse(ts);
  }

  static bool _isValidQuote(MarketPriceQuote quote) =>
      _names.containsKey(quote.productId) &&
      stores.containsKey(quote.country) &&
      quote.price > 0 && quote.price < 1000000 &&
      quote.currency == currencyFor(quote.country) &&
      !quote.retrievedAt.isAfter(DateTime.now().add(const Duration(minutes: 10)));

  /// Backend/AI/izinli market entegrasyonundan gelen fiyatları doğrular ve saklar.
  static Future<int> saveQuotes(Iterable<MarketPriceQuote> quotes) async {
    var saved = 0;
    for (final quote in quotes) {
      if (!_isValidQuote(quote)) continue;
      _quotes[_quoteId(quote.country, quote.productId)] = quote;
      saved++;
    }
    if (saved == 0) return 0;
    lastPriceUpdate = DateTime.now();
    await HiveService.setSetting(_quoteKey, jsonEncode(_quotes.values.map((q) => q.toJson()).toList()));
    await HiveService.setSetting('market_price_updated_at', lastPriceUpdate!.toIso8601String());
    return saved;
  }

  /// Eski isim-fiyat akışını destekler; yeni kodda ürün kimliği tercih edilir.
  static Future<void> saveOverrides(Map<String, double> prices, {String country = 'BE'}) async {
    final now = DateTime.now();
    final quotes = <MarketPriceQuote>[];
    for (final entry in prices.entries) {
      _ProductSeed? seed;
      for (final candidate in _base) {
        if (candidate.id == entry.key || _names[candidate.id]!.values.contains(entry.key)) {
          seed = candidate;
          break;
        }
      }
      if (seed == null) continue;
      quotes.add(MarketPriceQuote(productId: seed.id, country: country.toUpperCase(), price: entry.value,
          currency: currencyFor(country), market: 'AI average', retrievedAt: now));
    }
    await saveQuotes(quotes);
  }

  static List<MarketProduct> productsFor(String country, {String? category, String language = 'tr'}) {
    final normalizedCountry = stores.containsKey(country.toUpperCase()) ? country.toUpperCase() : 'BE';
    return _base.where((p) => category == null || p.categoryId == category || categoryName(p.categoryId, language) == category).map((p) {
      final quote = _quotes[_quoteId(normalizedCountry, p.id)];
      // TRY için sahte kur dönüşümü yapılmaz; güncel kayıt yoksa fiyat 0 gösterilir.
      final fallback = normalizedCountry == 'TR' ? 0.0 : p.fallbackEur;
      return MarketProduct(id: p.id, emoji: p.emoji, name: _text(_names[p.id]!, language),
          price: quote?.price ?? fallback, category: categoryName(p.categoryId, language),
          currency: quote?.currency ?? currencyFor(normalizedCountry), sourceMarket: quote?.market,
          sourceUrl: quote?.sourceUrl, priceUpdatedAt: quote?.retrievedAt);
    }).toList(growable: false);
  }

  static int weekNumber(DateTime d) {
    final thursday = d.add(Duration(days: 4 - d.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    return 1 + (thursday.difference(firstThursday.subtract(Duration(days: firstThursday.weekday - 4))).inDays ~/ 7);
  }

  static List<MarketProduct> weeklyDeals(String country, {int count = 6, String language = 'tr'}) {
    final all = productsFor(country, language: language);
    if (all.isEmpty) return const [];
    final start = (weekNumber(DateTime.now()) * 3) % all.length;
    return List.generate(count.clamp(0, all.length), (i) => all[(start + i * 5) % all.length]);
  }

  static DateTime weekMonday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }
}
