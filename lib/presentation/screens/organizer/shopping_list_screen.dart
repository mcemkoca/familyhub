import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/constants.dart';
import '../../../config/market_catalog.dart';
import '../../../domain/entities.dart';
import '../../../services/hive_service.dart';
import '../../../services/ai/ai_content_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/screen_background.dart';

// Quick AI-suggested common items (tokensiz)
const _aiSuggestions = [
  ('🥛', 'Süt'),
  (('🍞', 'Ekmek')),
  ('🥚', 'Yumurta'),
  ('🧀', 'Peynir'),
  (('🍅', 'Domates')),
  ('🧅', 'Soğan'),
  ('🫒', 'Zeytinyağı'),
  (('🍗', 'Tavuk')),
  ('🌿', 'Maydanoz'),
  (('🍋', 'Limon')),
  ('🧴', 'Deterjan'),
  ('🧻', 'Tuvalet Kağıdı'),
];

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() =>
      _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  ShoppingCategory _selectedCategory = ShoppingCategory.grocery;
  ShoppingUnit _selectedUnit = ShoppingUnit.piece;
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final raw = await rootBundle.loadString('assets/data/content/recipes.json');
      setState(() {
        _recipes = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _toggleItem(ShoppingItem item) {
    HapticFeedback.selectionClick();
    ref.read(shoppingItemsProvider.notifier).toggleItem(item);
  }

  void _addItem([String? quickName]) {
    final name = quickName ?? _nameController.text.trim();
    if (name.isEmpty) return;

    // Miktar doğrulama — negatif/0/aşırı büyük değerleri engelle (1..999).
    int? quantity;
    if (_quantityController.text.trim().isNotEmpty) {
      final parsed = int.tryParse(_quantityController.text.trim());
      if (parsed == null || parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).shoppingGecerliMiktar)),
        );
        return;
      }
      quantity = parsed.clamp(1, 999);
    }

    // Duplicate koruması — aynı ada sahip bekleyen ürün varsa sessizce ikinci
    // satır oluşturma; kullanıcıyı bilgilendir.
    final existing = ref.read(shoppingItemsProvider).valueOrNull ?? [];
    final norm = name.trim().toLowerCase();
    final dup = existing.any((i) => !i.isCompleted && i.name.trim().toLowerCase() == norm);
    if (dup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).shoppingZatenListede(name))),
      );
      if (quickName == null) {
        _nameController.clear();
        _quantityController.clear();
        Navigator.pop(context);
      }
      return;
    }

    ref.read(shoppingItemsProvider.notifier).addItem(
          name,
          quantity: quantity,
          category: _selectedCategory,
          unit: _selectedUnit,
        );
    _nameController.clear();
    _quantityController.clear();
    if (quickName == null) Navigator.pop(context);
  }

  /// Ürünü siler; kullanıcıya "Geri al" seçeneği sunar (yanlış silmeyi önler).
  void _deleteItem(ShoppingItem item) {
    ref.read(shoppingItemsProvider.notifier).deleteItem(item.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).shoppingSilindi(item.name)),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context).shoppingGeriAl,
          onPressed: () {
            ref.read(shoppingItemsProvider.notifier).addItem(
                  item.name,
                  quantity: int.tryParse(item.quantity ?? ''),
                  category: item.category,
                  unit: item.unit,
                );
          },
        ),
      ),
    );
  }

  IconData _categoryIcon(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.pharmacy:
        return Icons.local_pharmacy_outlined;
      case ShoppingCategory.stationery:
        return Icons.edit_note_outlined;
      case ShoppingCategory.household:
        return Icons.cleaning_services_outlined;
      case ShoppingCategory.grocery:
        return Icons.shopping_basket_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _categoryColor(ShoppingCategory cat) {
    switch (cat) {
      case ShoppingCategory.pharmacy:
        return AppColors.error;
      case ShoppingCategory.stationery:
        return const Color(0xFF6366F1);
      case ShoppingCategory.household:
        return const Color(0xFF10B981);
      default:
        return AppColors.orange;
    }
  }

  String _unitLabel(ShoppingUnit u) {
    final t = AppLocalizations.of(context);
    return switch (u) {
      ShoppingUnit.piece => t.unitPiece,
      ShoppingUnit.pack => t.unitPack,
      ShoppingUnit.box => t.unitBox,
      ShoppingUnit.bottle => t.unitBottle,
      ShoppingUnit.jar => t.unitJar,
      ShoppingUnit.liter => t.unitLiter,
      ShoppingUnit.milliliter => t.unitMilliliter,
      ShoppingUnit.kilogram => t.unitKilogram,
      ShoppingUnit.gram => t.unitGram,
      ShoppingUnit.bunch => t.unitBunch,
      ShoppingUnit.dozen => t.unitDozen,
      ShoppingUnit.portion => t.unitPortion,
    };
  }

  String _categoryLabel(ShoppingCategory cat) {
    final t = AppLocalizations.of(context);
    switch (cat) {
      case ShoppingCategory.pharmacy:
        return t.shoppingKatEczane;
      case ShoppingCategory.stationery:
        return t.shoppingKatKirtasiye;
      case ShoppingCategory.household:
        return t.shoppingKatEv;
      case ShoppingCategory.grocery:
        return t.shoppingKatMarket;
      default:
        return t.shoppingKatDiger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingItemsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ScreenBackground(
        asset: 'assets/images/backgrounds/shopping_bg.png',
        child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, itemsAsync),
            // AI Suggestions toggle
            if (_showSuggestions) _buildAISuggestions(isDark),
            Expanded(
              child: itemsAsync.when(
                data: (items) => _buildList(items, isDark),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildError(),
              ),
            ),
          ],
        ),
        ),
      ),
      // FAB'ı alt nav çubuğunun (MainShell iki-pill) üstüne kaldır — yoksa
      // arkasında kalıp görünmez.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddSheet(context),
          backgroundColor: const Color(0xFF10B981),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(AppLocalizations.of(context).shoppingEkle,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark,
      AsyncValue<List<ShoppingItem>> itemsAsync) {
    final total = itemsAsync.valueOrNull?.length ?? 0;
    final done =
        itemsAsync.valueOrNull?.where((i) => i.isCompleted).length ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: const Color(0x1AFFFFFF),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shopping_cart,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).alisverisListesi,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (total > 0)
                      Text(
                        AppLocalizations.of(context)
                            .shoppingTamamlandiOran(done, total),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280)),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openNearbyMarketsMap,
                icon: const Icon(Icons.location_on_outlined),
                color: const Color(0xFF3B82F6),
                tooltip: AppLocalizations.of(context).shoppingTipYakinMarket,
              ),
              IconButton(
                onPressed: _showMarketCatalog,
                icon: const Icon(Icons.storefront_outlined),
                color: const Color(0xFF10B981),
                tooltip: AppLocalizations.of(context).shoppingTipMarketKatalogu,
              ),
              IconButton(
                onPressed: _showAiMarketList,
                icon: const Icon(Icons.auto_awesome_motion_outlined),
                color: const Color(0xFF8B5CF6),
                tooltip: AppLocalizations.of(context).shoppingTipAiMarket,
              ),
              IconButton(
                onPressed: _showRecipePicker,
                icon: const Icon(Icons.restaurant_menu_outlined),
                color: AppColors.orange,
                tooltip: AppLocalizations.of(context).shoppingTipTarifeGore,
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _showSuggestions = !_showSuggestions),
                icon: Icon(
                  Icons.auto_awesome,
                  color: _showSuggestions
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6B7280),
                ),
                tooltip: AppLocalizations.of(context).shoppingHizliEkle,
              ),
              IconButton(
                onPressed: () =>
                    ref.read(shoppingItemsProvider.notifier).loadItems(),
                icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                backgroundColor: const Color(0x1EFFFFFF),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Anlık konumu alır ve OpenStreetMap tabanlı harita uygulamasında yakındaki
  /// marketleri açar (geo: URI → cihaz harita uygulaması; olmazsa OSM web).
  Future<void> _openNearbyMarketsMap() async {
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(t.shoppingKonumAliniyor),
      duration: const Duration(seconds: 1),
    ));
    try {
      // İzin kontrolü + iste.
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        messenger.showSnackBar(SnackBar(
          content: Text(t.shoppingKonumIzniYok),
          backgroundColor: const Color(0xFFEF4444),
        ));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      final lat = pos.latitude;
      final lon = pos.longitude;

      // Anlık konumu kullanıcıya yaz.
      messenger.showSnackBar(SnackBar(
        content: Text(t.shoppingKonumBulundu(
            '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}')),
        duration: const Duration(seconds: 2),
      ));

      // Önce cihazın harita uygulaması (yakındaki süpermarketleri arar).
      final geoUri = Uri.parse('geo:$lat,$lon?q=supermarket');
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
      // Yedek: OpenStreetMap web (anlık konum işaretli).
      final osmUri = Uri.parse(
          'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=16/$lat/$lon');
      await launchUrl(osmUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(t.shoppingKonumAlinamadi),
        backgroundColor: const Color(0xFFEF4444),
      ));
    }
  }

  void _showMarketCatalog() {
    final country = HiveService.getSetting('country') ?? 'BE';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarketCatalogSheet(
        country: country,
        onAdd: (p) {
          ref.read(shoppingItemsProvider.notifier).addItem(p.name);
        },
      ),
    );
  }

  void _showAiMarketList() {
    final country = HiveService.getSetting('country') ?? 'BE';
    final markets = AiContentService.marketsForCountry(country);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF13131A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: AiContentService.weeklyList(
              topic: 'market_list_$country',
              prompt:
                  'Bir aile için bu haftaya özel akıllı alışveriş listesi '
                  'oluştur. Bölge marketleri: ${markets.join(", ")}. '
                  'Ürünleri hangi markette daha uygun/bulunur ise o markete '
                  'ata. Sadece JSON döndür: {"items":[{"market":"${markets.first}",'
                  '"name":"...","note":"~2,50€"}]}. 12-16 temel ürün, Türkçe.',
              listKey: 'items',
              fallback: const [],
              maxTokens: 1200,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context).shoppingAiHazirlaniyor,
                            style: const TextStyle(color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                );
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                        AppLocalizations.of(context).shoppingListeOlusturulamadi,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF9CA3AF))),
                  ),
                );
              }
              // Markete göre grupla.
              final byMarket = <String, List<Map<String, dynamic>>>{};
              for (final it in items) {
                final m = (it['market']?.toString() ?? markets.first);
                byMarket.putIfAbsent(m, () => []).add(it);
              }
              return ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_motion,
                          color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(AppLocalizations.of(context).shoppingAiMarketBaslik,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context).shoppingDokunEkle,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                  const SizedBox(height: 16),
                  for (final entry in byMarket.entries) ...[
                    Row(
                      children: [
                        const Icon(Icons.storefront,
                            size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(entry.key,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final it in entry.value)
                      GestureDetector(
                        onTap: () {
                          final name = it['name']?.toString() ?? '';
                          if (name.isEmpty) return;
                          ref
                              .read(shoppingItemsProvider.notifier)
                              .addItem(name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(AppLocalizations.of(context)
                                    .shoppingListeyeEklendi(name)),
                                behavior: SnackBarBehavior.floating),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A24),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFF262631)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(it['name']?.toString() ?? '',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14.5)),
                              ),
                              if (it['note'] != null)
                                Text(it['note'].toString(),
                                    style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 12.5)),
                              const SizedBox(width: 8),
                              const Icon(Icons.add_circle_outline,
                                  color: Color(0xFF10B981), size: 20),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        for (final it in items) {
                          final name = it['name']?.toString() ?? '';
                          if (name.isNotEmpty) {
                            ref
                                .read(shoppingItemsProvider.notifier)
                                .addItem(name);
                          }
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .shoppingTumUrunlerEklendi),
                              behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.playlist_add_check,
                          color: Colors.white),
                      label: Text(AppLocalizations.of(context).shoppingTumunuEkle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRecipePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = _recipes.where((r) {
              final title = (r['title'] as String? ?? '').toLowerCase();
              final cat = (r['category'] as String? ?? '').toLowerCase();
              return query.isEmpty || title.contains(query) || cat.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollCtrl) => Container(
                decoration: const BoxDecoration(
                  color: Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x1EFFFFFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context).shoppingTarifeGoreBaslik,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                              color: Color(0xFFE5E7EB))),
                          const SizedBox(height: 4),
                          Text(AppLocalizations.of(context).shoppingTarifSayisi('${_recipes.length}'),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          const SizedBox(height: 12),
                          TextField(
                            controller: searchCtrl,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).shoppingTarifAra,
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: const Color(0xFF0A0A0F),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (_) => setLocal(() {}),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final recipe = filtered[i];
                          final title = recipe['title'] as String? ?? '';
                          final time = (recipe['cook_time'] ?? recipe['prep_time'] ?? 0).toString();
                          final ingredientCount = (recipe['ingredients'] as List?)?.length ?? 0;
                          final cat = _categoryEmoji(recipe['category'] as String? ?? '');
                          return ListTile(
                            leading: Text(cat, style: const TextStyle(fontSize: 24)),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE5E7EB))),
                            subtitle: Text(AppLocalizations.of(context).shoppingTarifMeta(time, '$ingredientCount'),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _addFromRecipe(recipe);
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ekle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _categoryEmoji(String cat) {
    return switch (cat) {
      'kahvalti' => '🍳',
      'corba' => '🍲',
      'ana_yemek' => '🍖',
      'tatli' => '🍮',
      'salata' => '🥗',
      'meze' => '🍫™',
      'pilav' => '🍚',
      'hamur_isi' => '🥐™',
      'dolma_sarma' => '🫑',
      'makarna' => '🍝',
      'balik' => '🐟',
      'atistirmalik' => '🥨',
      'icecek' => '🥤',
      'sebze_yemegi' => '🥦',
      _ => '🍽️',
    };
  }

  void _addFromRecipe(Map<String, dynamic> recipe) {
    final ingredients = (recipe['ingredients'] as List?) ?? [];
    int added = 0;
    for (final ing in ingredients) {
      final name = (ing as Map?)?['name'] as String? ?? '';
      if (name.isNotEmpty) {
        ref.read(shoppingItemsProvider.notifier).addItem(
          name,
          category: ShoppingCategory.grocery,
        );
        added++;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)
            .shoppingMalzemeEklendi(recipe['title']?.toString() ?? '', added)),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Widget _buildAISuggestions(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      color: isDark
          ? const Color(0xFF13131A).withAlpha(200)
          : const Color(0xFF10B981).withAlpha(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).shoppingHizliEkle,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _aiSuggestions.map((s) {
              final (emoji, name) = s;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _addItem(name);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(6), blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE5E7EB))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).shoppingYuklenemedi,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA3AF), height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(shoppingItemsProvider.notifier).loadItems(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context).shoppingTekrarDene),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ShoppingItem> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withAlpha(24),
                ),
                child: Icon(Icons.shopping_cart_outlined,
                    size: 56, color: const Color(0xFF10B981).withAlpha(200)),
              ),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context).shoppingListenBos,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).shoppingBosAciklama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5, color: Color(0xFF9CA3AF), height: 1.4),
              ),
              const SizedBox(height: 24),
              // Belirgin ana eylem — FAB nav'ın arkasında kalsa da buradan eklenir.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showAddSheet(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(AppLocalizations.of(context).urunEkle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showRecipePicker,
                      icon: const Icon(Icons.restaurant_menu,
                          size: 18, color: Color(0xFFF97316)),
                      label: Text(AppLocalizations.of(context).shoppingTariften,
                          style: const TextStyle(color: Color(0xFFF97316))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showAiMarketList,
                      icon: const Icon(Icons.auto_awesome,
                          size: 18, color: Color(0xFF8B5CF6)),
                      label: Text(AppLocalizations.of(context).shoppingAiListe,
                          style: const TextStyle(color: Color(0xFF8B5CF6))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final pending = items.where((i) => !i.isCompleted).toList();
    final done = items.where((i) => i.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionLabel(
              AppLocalizations.of(context).shoppingBekleyen, pending.length, isDark),
          const SizedBox(height: 8),
          ...pending.map((item) => _buildItemCard(item, isDark)),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel(
              AppLocalizations.of(context).shoppingTamamlanan, done.length, isDark,
              color: const Color(0xFF10B981)),
          const SizedBox(height: 8),
          ...done.map((item) => _buildItemCard(item, isDark)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, int count, bool isDark,
      {Color color = const Color(0xFF6B7280)}) {
    return Row(
      children: [
        Text(
          '$label ($count)',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildItemCard(ShoppingItem item, bool isDark) {
    final catColor = _categoryColor(item.category);
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: AppColors.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Semantics(
            checked: item.isCompleted,
            label: item.name,
            value: [
              if (item.quantity != null)
                '${item.quantity} ${_unitLabel(item.unit)}',
              _categoryLabel(item.category),
            ].join(', '),
            child: GestureDetector(
              onTap: () => _toggleItem(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: item.isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0x1EFFFFFF),
                      width: 2),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration:
                  item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted
                  ? const Color(0xFF6B7280)
                  : (const Color(0xFFE5E7EB)),
            ),
          ),
          subtitle: item.quantity != null
              ? Text(
                  '${item.quantity} ${_unitLabel(item.unit)}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)))
              : null,
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: catColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_categoryIcon(item.category), size: 12, color: catColor),
                const SizedBox(width: 4),
                Text(_categoryLabel(item.category),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: catColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF13131A),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: const Color(0x1EFFFFFF),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(AppLocalizations.of(context).urunEkle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).shoppingUrunAdi,
                  prefixIcon: const Icon(Icons.shopping_basket_outlined),
                  filled: true,
                  fillColor:
                      const Color(0xFF0A0A0F),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).shoppingAdetOpsiyonel,
                        prefixIcon: const Icon(Icons.numbers),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0A0A0F)
                            : const Color(0xFF0A0A0F),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Unit picker
              Text(AppLocalizations.of(context).shoppingBirim,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ShoppingUnit.values.map((u) {
                  final active = _selectedUnit == u;
                  return GestureDetector(
                    onTap: () => setModal(
                        () => setState(() => _selectedUnit = u)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF6366F1)
                            : const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_unitLabel(u),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Category picker
              Text(AppLocalizations.of(context).shoppingKategori,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ShoppingCategory.values.map((cat) {
                  final active = _selectedCategory == cat;
                  final color = _categoryColor(cat);
                  return GestureDetector(
                    onTap: () => setModal(
                        () => setState(() => _selectedCategory = cat)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? color
                            : color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_categoryIcon(cat),
                              size: 13,
                              color: active ? Colors.white : color),
                          const SizedBox(width: 5),
                          Text(_categoryLabel(cat),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      active ? Colors.white : color)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(AppLocalizations.of(context).shoppingListeyeEkle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// Market Kataloğu — ülkeye göre marketler + haftalık fırsatlar + ürünler
// ═══════════════════════════════════════════════════════════════════════════
class _MarketCatalogSheet extends StatefulWidget {
  final String country;
  final void Function(MarketProduct) onAdd;
  const _MarketCatalogSheet({required this.country, required this.onAdd});

  @override
  State<_MarketCatalogSheet> createState() => _MarketCatalogSheetState();
}

class _MarketCatalogSheetState extends State<_MarketCatalogSheet> {
  String _category = 'Tümü';
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    MarketCatalog.loadOverrides();
  }

  String get _cur =>
      HiveService.getSetting('currencySymbol') ?? (widget.country == 'TR' ? '₺' : '€');

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  /// AI ile güncel (Belçika) ortalama market fiyatlarını çeker, Hive'a kaydeder.
  Future<void> _refreshPrices() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final names = MarketCatalog.productNames;
    try {
      final items = await AiContentService.weeklyList(
        topic: 'market_prices_${widget.country}',
        forceRefresh: true,
        maxTokens: 1100,
        prompt:
            'Aşağıdaki market ürünleri için ${widget.country == 'TR' ? 'Türkiye' : 'Belçika'} '
            'süpermarketlerindeki (Aldi, Lidl, Colruyt) GÜNCEL ortalama birim '
            'fiyatını EUR cinsinden tahmin et. Sadece JSON döndür: '
            '{"items":[{"name":"<ürün adı aynen>","price":<sayı>}]}. '
            'Ürünler: ${names.join(", ")}.',
        fallback: const [],
      );
      final prices = <String, double>{};
      for (final it in items) {
        final n = it['name']?.toString();
        final p = it['price'];
        if (n != null && p is num) prices[n] = p.toDouble();
      }
      if (prices.isNotEmpty) {
        await MarketCatalog.saveOverrides(prices);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prices.isEmpty
                ? AppLocalizations.of(context).shoppingFiyatGuncellenemedi
                : AppLocalizations.of(context).shoppingMalzemeEklendi('', prices.length)),
            backgroundColor: prices.isEmpty
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).shoppingFiyatBasarisiz)),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markets = MarketCatalog.marketsFor(widget.country);
    final deals = MarketCatalog.weeklyDeals(widget.country);
    final cats = ['Tümü', ...MarketCatalog.categories];
    final products = MarketCatalog.productsFor(widget.country,
        category: _category == 'Tümü' ? null : _category);
    final monday = MarketCatalog.weekMonday();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.storefront, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).shoppingMarketKatalogu,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(
                      AppLocalizations.of(context).shoppingGuncellendi(
                          _fmtDate(MarketCatalog.lastPriceUpdate ?? monday)),
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 11)),
                  const SizedBox(width: 6),
                  _refreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF10B981)))
                      : IconButton(
                          onPressed: _refreshPrices,
                          visualDensity: VisualDensity.compact,
                          tooltip: AppLocalizations.of(context).shoppingFiyatlariGuncelle,
                          icon: const Icon(Icons.refresh_rounded,
                              color: Color(0xFF10B981), size: 20),
                        ),
                ],
              ),
            ),
            // Market rozetleri
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: markets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  child: Text(markets[i],
                      style: const TextStyle(
                          color: Color(0xFFC7CBD4),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // Bu haftanın fırsatları
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Color(0xFFF97316), size: 18),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context).shoppingHaftaninFirsatlari,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: deals.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final p = deals[i];
                        return GestureDetector(
                          onTap: () => _add(p),
                          child: Container(
                            width: 90,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                const Color(0xFFF97316).withAlpha(30),
                                const Color(0xFFF97316).withAlpha(12),
                              ]),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFF97316).withAlpha(80)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const Spacer(),
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                                Text('$_cur${p.price.toStringAsFixed(p.price >= 100 ? 0 : 2)}',
                                    style: const TextStyle(
                                        color: Color(0xFFF97316),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Kategori filtresi
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = cats[i];
                        final sel = _category == c;
                        return GestureDetector(
                          onTap: () => setState(() => _category = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF1A1A24),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                                c == 'Tümü'
                                    ? AppLocalizations.of(context).shoppingTumu
                                    : c,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white
                                        : const Color(0xFF9CA3AF))),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Ürün ızgarası
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return GestureDetector(
                        onTap: () => _add(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A24),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x18FFFFFF)),
                          ),
                          child: Row(
                            children: [
                              Text(p.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600)),
                                    Text('$_cur${p.price.toStringAsFixed(p.price >= 100 ? 0 : 2)}',
                                        style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.add_circle,
                                  color: Color(0xFF10B981), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _add(MarketProduct p) {
    widget.onAdd(p);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).shoppingListeyeEklendi(p.name)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900)));
  }
}
