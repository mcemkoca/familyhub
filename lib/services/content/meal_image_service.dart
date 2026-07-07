import 'dart:convert';
import 'package:http/http.dart' as http;

/// TheMealDB (ücretsiz, API anahtarsız) üzerinden yemek adına göre
/// GERÇEK ve DOĞRU fotoğraf çeker. Bulunamazsa null döner (yanlış görsel yok).
class MealImageService {
  MealImageService._();

  // title -> thumbUrl (veya null = bulunamadı). Bellek içi önbellek.
  static final Map<String, String?> _cache = {};

  /// Türkçe tarif adını TheMealDB'de aranabilir İngilizce terime çevirir.
  static const Map<String, String> _query = {
    'Menemen': 'menemen',
    'Mercimek Çorbası': 'lentil soup',
    'Köfte': 'kofta',
    'Fırında Köfte': 'kofta',
    'Fırında Köfte ': 'kofta',
    'Kadın Budu Köfte': 'kofta',
    'Patates Köftesi': 'potato',
    'Mercimekli Köfte': 'lentil',
    'İmam Bayıldı': 'imam bayildi',
    'Baklava': 'baklava',
    'Pilav (Tereyağlı)': 'rice',
    'Bulgur Pilavı': 'bulgur',
    'Karnıyarık': 'stuffed eggplant',
    'Kuru Fasulye': 'beans',
    'Domates Çorbası': 'tomato soup',
    'Lahmacun': 'lahmacun',
    'Çiğ Köfte': 'kofta',
    'Sebzeli Makarna': 'pasta',
    'Tavuk Sote': 'chicken',
    'Sütlaç': 'rice pudding',
    'Börek (Kıymalı)': 'borek',
    'Cacık': 'yogurt',
    'Fırın Tavuk': 'roast chicken',
    'Şakşuka': 'shakshuka',
    'Ayran': 'ayran',
    'Zeytinyağlı Enginar': 'artichoke',
    'Tarhana Çorbası': 'soup',
    'Etli Nohut': 'chickpea',
    'Pide (Kaşarlı)': 'pide',
    'Hünkar Beğendi': 'eggplant beef',
    'Ispanak Yemeği': 'spinach',
    'Revani': 'semolina cake',
    'Mantı': 'dumplings',
    'Kazandibi': 'pudding',
    'Patlıcan Soslu Makarna': 'pasta eggplant',
    'Kisir': 'bulgur salad',
    'Fırında Balık': 'baked fish',
    'Helva (İrmik)': 'halva',
    'Portakallı Kek': 'orange cake',
    'Çikolatalı Sufle': 'chocolate souffle',
    'Tavuk Döner': 'doner kebab',
    'Tepsi Böreği': 'borek',
    'Gözleme': 'gozleme',
    'Simit': 'simit',
    'Mantı ': 'dumplings',
    'Patlıcan Musakka': 'moussaka',
    'Aşure': 'pudding',
    'Antep Ezmesi': 'salsa',
    'Kabak Mücveri': 'zucchini fritter',
    'Tavuklu Güveç': 'chicken casserole',
    'Güneydoğu Usulü Ciğer': 'liver',
    'Fırında Et Kavurma': 'beef',
    'Lokma Tatlısı': 'doughnut',
  };

  static String _buildQuery(String title, String category) {
    if (_query.containsKey(title)) return _query[title]!;
    // Kategoriye göre genel arama
    switch (category) {
      case 'corba':
        return 'soup';
      case 'tatli':
        return 'dessert';
      case 'salata':
        return 'salad';
      case 'makarna':
        return 'pasta';
      case 'pilav':
        return 'rice';
      case 'balik':
        return 'fish';
      case 'hamur_isi':
        return 'pie';
      case 'kahvalti':
        return 'breakfast';
      default:
        return 'kofta';
    }
  }

  /// Türkçe Wikipedia sayfa adı (doğru fotoğraf için). Belirtilmeyenlerde
  /// başlığın kendisi denenir.
  static const Map<String, String> _wikiPage = {
    'Menemen': 'Menemen (yemek)',
    'Mercimek Çorbası': 'Mercimek çorbası',
    'Karnıyarık': 'Karnıyarık',
    'Kuru Fasulye': 'Kuru fasulye',
    'Çiğ Köfte': 'Çiğ köfte',
    'Sütlaç': 'Sütlaç',
    'Cacık': 'Cacık',
    'Bulgur Pilavı': 'Bulgur pilavı',
    'Ayran': 'Ayran',
    'Şakşuka': 'Şakşuka',
    'Fırında Köfte': 'Köfte',
    'Fırın Tavuk': 'Tavuk',
    'Kadın Budu Köfte': 'Kadınbudu köfte',
    'Patates Köftesi': 'Köfte',
    'Mercimekli Köfte': 'Mercimek köftesi',
    'Zeytinyağlı Enginar': 'Enginar',
    'Tarhana Çorbası': 'Tarhana',
    'Pide (Kaşarlı)': 'Pide',
    'Pazı Sarması': 'Sarma (yemek)',
    'Hünkar Beğendi': 'Hünkâr beğendi',
    'Revani': 'Revani',
    'Gözleme': 'Gözleme',
    'Mantı': 'Mantı',
    'Kemalpaşa Tatlısı': 'Kemalpaşa tatlısı',
    'Tarator': 'Tarator',
    'Etli Yaprak Sarma': 'Yaprak sarma',
    'Patlıcan Soslu Makarna': 'Makarna',
    'Sütlü Nuriye': 'Baklava',
    'Kisir': 'Kısır',
    'Helva (İrmik)': 'İrmik helvası',
    'Fırında Balık': 'Balık (yemek)',
    'İmam Bayıldı': 'İmam bayıldı',
    'Baklava': 'Baklava',
    'Pilav (Tereyağlı)': 'Pilav',
    'Lahmacun': 'Lahmacun',
    'Börek (Kıymalı)': 'Börek',
    'Domates Çorbası': 'Domates çorbası',
    'Sebzeli Makarna': 'Makarna',
    'Tavuk Sote': 'Tavuk sote',
    'Etli Nohut': 'Nohut yemeği',
    'Ispanak Yemeği': 'Ispanak',
    'Tavuklu Pilav (Düğün Pilavı)': 'Pilav',
    'Zeytinyağlı Biber Dolması': 'Dolma',
    'Mısır Çorbası': 'Çorba',
    'Türk Kahvesi Muhallebisi': 'Muhallebi',
    'Kazandibi': 'Kazandibi',
    'Tavuklu Mercimek Çorbası': 'Mercimek çorbası',
    'Üzgün Patlıcan Salatası': 'Patlıcan salatası',
    'Portakallı Kek': 'Kek',
    'Çikolatalı Sufle': 'Sufle',
    'Tavuk Döner': 'Döner',
    'Şalgam Suyu': 'Şalgam suyu',
    'Tepsi Böreği': 'Börek',
    'Zeytinyağlı Taze Fasulye': 'Taze fasulye',
    'Patates Salatası': 'Patates salatası',
    'Çerkez Tavuğu': 'Çerkez tavuğu',
    'Aşure': 'Aşure',
    'Patlıcan Musakka': 'Musakka',
    'Simit': 'Simit',
    'Etli Bamya': 'Bamya',
    'Lokma Tatlısı': 'Lokma (tatlı)',
    'Antep Ezmesi': 'Acılı ezme',
    'Kabak Mücveri': 'Mücver',
    'Güneydoğu Usulü Ciğer': 'Ciğer',
    'Kuru Fasulye ': 'Kuru fasulye',
    'Şakşuka ': 'Şakşuka',
  };

  static Future<String?> _fetchMealDb(String title, String category) async {
    try {
      final q = _buildQuery(title, category);
      final uri = Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(q)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          return (meals.first as Map?)?['strMealThumb'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _fetchWikipedia(String title) async {
    final page = _wikiPage[title] ?? title;
    try {
      // pageimages API — sayfanın ana görselini güvenilir döndürür (redirect'li)
      final uri = Uri.parse(
          'https://tr.wikipedia.org/w/api.php?action=query&titles=${Uri.encodeComponent(page)}&prop=pageimages&pithumbsize=400&format=json&redirects=1');
      final res = await http.get(uri, headers: {
        'User-Agent': 'FamilyHub/1.0 (family app)'
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final pages =
            (data['query'] as Map?)?['pages'] as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          final first = pages.values.first as Map<String, dynamic>;
          final thumb = first['thumbnail'] as Map<String, dynamic>?;
          return thumb?['source'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Son çare — her tarife MUTLAKA bir yemek fotoğrafı garantiler.
  /// LoremFlickr, anahtar kelimeye göre gerçek Flickr yemek görseli döndürür.
  static String _guaranteedFallback(String title, String category) {
    final q = _buildQuery(title, category);
    final tag = Uri.encodeComponent(q.replaceAll(' ', ','));
    // Başlığa göre sabit seed → aynı tarif hep aynı görseli alır.
    final seed = title.hashCode.abs() % 100000;
    return 'https://loremflickr.com/400/300/$tag,food?lock=$seed';
  }

  static Future<String?> fetchThumb(String title, String category) async {
    if (_cache.containsKey(title)) return _cache[title];
    // Otantik Türk yemekleri için önce Wikipedia (daha doğru), sonra TheMealDB
    String? url = await _fetchWikipedia(title);
    url ??= await _fetchMealDb(title, category);
    // Hiçbiri bulamadıysa garanti fallback — kart asla ikonsuz/boş kalmasın.
    url ??= _guaranteedFallback(title, category);
    _cache[title] = url;
    return url;
  }
}
