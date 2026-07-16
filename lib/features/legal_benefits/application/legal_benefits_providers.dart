import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/app_providers.dart';
import '../data/legal_benefits_repository.dart';
import '../data/legal_article_repository.dart';
import '../domain/legal_article.dart';
import '../domain/legal_benefit.dart';

/// Arama sorgusu (aksan/harf duyarsız filtre ekranda uygulanır).
final legalSearchProvider = StateProvider<String>((ref) => '');

/// Seçili kategori filtresi (null → tümü).
final legalCategoryFilterProvider = StateProvider<LegalCategory?>((ref) => null);

/// Yalnızca kaydedilenleri göster.
final legalSavedOnlyProvider = StateProvider<bool>((ref) => false);

/// Kaydedilenlerin değiştiğini bildirmek için basit tick (UI yeniden okusun).
final legalSavedTickProvider = StateProvider<int>((ref) => 0);

/// Aktif ülkeye + filtrelere göre çözülmüş liste.
final legalBenefitsListProvider = Provider<List<LegalBenefit>>((ref) {
  final country = ref.watch(countryProvider);
  final query = ref.watch(legalSearchProvider).trim().toLowerCase();
  final cat = ref.watch(legalCategoryFilterProvider);
  final savedOnly = ref.watch(legalSavedOnlyProvider);
  ref.watch(legalSavedTickProvider); // kaydetme değişince yeniden hesapla

  final repo = LegalBenefitsRepository.instance;
  var items = repo.forCountry(country);

  if (cat != null) {
    items = items.where((b) => b.category == cat).toList();
  }
  if (savedOnly) {
    final saved = repo.savedIds();
    items = items.where((b) => saved.contains(b.id)).toList();
  }
  if (query.isNotEmpty) {
    String norm(String s) => _stripAccents(s.toLowerCase());
    final q = norm(query);
    items = items
        .where((b) =>
            norm(b.title).contains(q) || norm(b.description).contains(q))
        .toList();
  }
  // Süresi geçmişler en sona.
  items.sort((a, b) {
    if (a.isExpired != b.isExpired) return a.isExpired ? 1 : -1;
    return 0;
  });
  return items;
});

/// Aktif ülke + dile göre zengin yasal makaleler (JSON içerik katmanı).
/// Boşsa (dosya yok) UI yalnızca özet kartları gösterir.
final legalArticlesProvider =
    FutureProvider<List<LegalArticle>>((ref) async {
  final country = ref.watch(countryProvider);
  final lang = ref.watch(localeProvider).languageCode;
  return LegalArticleRepository.instance.forCountry(country, lang);
});

/// id → makale hızlı arama haritası (özet karttan detaya geçiş için).
final legalArticleByIdProvider =
    Provider<Map<String, LegalArticle>>((ref) {
  final async = ref.watch(legalArticlesProvider);
  final list = async.asData?.value ?? const <LegalArticle>[];
  return {for (final a in list) a.id: a};
});

String _stripAccents(String s) {
  const from = 'àáâäãåçèéêëìíîïñòóôöõùúûüýÿşğıİöçü';
  const to = 'aaaaaaceeeeiiiinooooouuuuyysgiiocu';
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString();
}
