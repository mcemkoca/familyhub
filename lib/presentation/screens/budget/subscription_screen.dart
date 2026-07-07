import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../services/hive_service.dart';

String get _cur => HiveService.getSetting('currencySymbol') ?? '€';

// ── Model ──

enum BillingCycle { monthly, yearly }

class Subscription {
  final String id;
  final String name;
  final String emoji;
  final double amount;
  final BillingCycle cycle;
  final String nextBilling;
  final String category;
  final List<String> sharedWith;
  final String color;
  final bool active;

  Subscription({
    required this.id,
    required this.name,
    required this.emoji,
    required this.amount,
    required this.cycle,
    required this.nextBilling,
    required this.category,
    this.sharedWith = const [],
    this.color = '#6C63FF',
    this.active = true,
  });

  double get monthlyAmount =>
      cycle == BillingCycle.monthly ? amount : amount / 12;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'amount': amount,
        'cycle': cycle.index,
        'nextBilling': nextBilling,
        'category': category,
        'sharedWith': sharedWith,
        'color': color,
        'active': active,
      };

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String? ?? '📱',
        amount: (j['amount'] as num).toDouble(),
        cycle: BillingCycle.values[j['cycle'] as int? ?? 0],
        nextBilling: j['nextBilling'] as String,
        category: j['category'] as String,
        sharedWith: List<String>.from(j['sharedWith'] as List? ?? []),
        color: j['color'] as String? ?? '#6C63FF',
        active: j['active'] as bool? ?? true,
      );

  Subscription copyWith({bool? active}) => Subscription(
        id: id,
        name: name,
        emoji: emoji,
        amount: amount,
        cycle: cycle,
        nextBilling: nextBilling,
        category: category,
        sharedWith: sharedWith,
        color: color,
        active: active ?? this.active,
      );
}

// ── Provider ──

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, List<Subscription>>(
  (ref) => SubscriptionNotifier(),
);

class SubscriptionNotifier extends StateNotifier<List<Subscription>> {
  SubscriptionNotifier() : super([]) {
    _load();
  }

  static const _boxName = 'subscriptions';
  static const _key = 'list';

  Future<Box<dynamic>> get _box async => Hive.isBoxOpen(_boxName)
      ? Hive.box(_boxName)
      : await Hive.openBox(_boxName);

  Future<void> _load() async {
    final b = await _box;
    final raw = b.get(_key);
    if (raw != null) {
      final list = jsonDecode(raw as String) as List;
      state = list
          .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _persist() async {
    final b = await _box;
    await b.put(_key, jsonEncode(state.map((s) => s.toJson()).toList()));
  }

  Future<void> add(Subscription sub) async {
    state = [...state, sub];
    await _persist();
  }

  Future<void> toggle(String id) async {
    state = state
        .map((s) => s.id == id ? s.copyWith(active: !s.active) : s)
        .toList();
    await _persist();
  }

  Future<void> delete(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _persist();
  }
}

// ── Predefined popular services ──

const _popularServices = [
  ('Kira', '🏠', 'Kira', '#6366F1'),
  ('Elektrik', '⚡', 'Elektrik', '#F59E0B'),
  ('Su', '💧', 'Su', '#06B6D4'),
  ('Doğalgaz', '🔥', 'Doğalgaz', '#EF4444'),
  ('İnternet', '🌐', 'İnternet', '#3B82F6'),
  ('Telefon', '📱', 'Telefon', '#F97316'),
  ('Sigorta', '🏥', 'Sigorta', '#10B981'),
  ('Aidat', '🏢', 'Diğer', '#8B5CF6'),
  ('Netflix', '🎬', 'Eğlence', '#E50914'),
  ('Spotify', '🎵', 'Müzik', '#1DB954'),
  ('Okul/Kreş', '🎒', 'Eğitim', '#EC4899'),
  ('Diğer', '🧾', 'Diğer', '#6C63FF'),
];

const _categories = [
  'Tümü', 'Kira', 'Elektrik', 'Su', 'Doğalgaz', 'İnternet', 'Telefon',
  'Sigorta', 'Eğlence', 'Müzik', 'Depolama', 'Eğitim', 'Diğer'
];

// ── Ülke bazlı tipik hane giderleri (aylık ortalama, yerel para/EUR) ──
// name, emoji, kategori, aylık tutar, renk
const _countryExpenses = {
  'BE': ( 'Belçika 🇧🇪', [
    ('Kira', '🏠', 'Kira', 1100.0, '#6366F1'),
    ('Elektrik (Engie)', '⚡', 'Elektrik', 95.0, '#F59E0B'),
    ('Su (Vivaqua)', '💧', 'Su', 35.0, '#06B6D4'),
    ('Doğalgaz', '🔥', 'Doğalgaz', 110.0, '#EF4444'),
    ('İnternet (Proximus)', '🌐', 'İnternet', 55.0, '#3B82F6'),
    ('Telefon (Orange)', '📱', 'Telefon', 20.0, '#F97316'),
    ('Sağlık sigortası', '🏥', 'Sigorta', 130.0, '#10B981'),
    ('Netflix', '🎬', 'Eğlence', 13.0, '#E50914'),
  ]),
  'TR': ( 'Türkiye 🇹🇷', [
    ('Kira', '🏠', 'Kira', 15000.0, '#6366F1'),
    ('Elektrik', '⚡', 'Elektrik', 900.0, '#F59E0B'),
    ('Su', '💧', 'Su', 300.0, '#06B6D4'),
    ('Doğalgaz', '🔥', 'Doğalgaz', 1200.0, '#EF4444'),
    ('İnternet (Türk Telekom)', '🌐', 'İnternet', 450.0, '#3B82F6'),
    ('Telefon', '📱', 'Telefon', 350.0, '#F97316'),
    ('DASK/Sigorta', '🏥', 'Sigorta', 500.0, '#10B981'),
    ('Netflix', '🎬', 'Eğlence', 200.0, '#E50914'),
  ]),
  'NL': ( 'Hollanda 🇳🇱', [
    ('Kira (Huur)', '🏠', 'Kira', 1250.0, '#6366F1'),
    ('Elektrik+Gaz (Vattenfall)', '⚡', 'Elektrik', 180.0, '#F59E0B'),
    ('Su (Vitens)', '💧', 'Su', 30.0, '#06B6D4'),
    ('İnternet (Ziggo)', '🌐', 'İnternet', 50.0, '#3B82F6'),
    ('Telefon (KPN)', '📱', 'Telefon', 22.0, '#F97316'),
    ('Zorgverzekering', '🏥', 'Sigorta', 140.0, '#10B981'),
    ('Spotify', '🎵', 'Müzik', 11.0, '#1DB954'),
  ]),
  'FR': ( 'Fransa 🇫🇷', [
    ('Kira (Loyer)', '🏠', 'Kira', 1000.0, '#6366F1'),
    ('Elektrik (EDF)', '⚡', 'Elektrik', 90.0, '#F59E0B'),
    ('Su', '💧', 'Su', 35.0, '#06B6D4'),
    ('Doğalgaz (Engie)', '🔥', 'Doğalgaz', 100.0, '#EF4444'),
    ('İnternet (Orange)', '🌐', 'İnternet', 40.0, '#3B82F6'),
    ('Telefon (SFR)', '📱', 'Telefon', 20.0, '#F97316'),
    ('Mutuelle santé', '🏥', 'Sigorta', 60.0, '#10B981'),
    ('Netflix', '🎬', 'Eğlence', 14.0, '#E50914'),
  ]),
  'DE': ( 'Almanya 🇩🇪', [
    ('Kira (Miete)', '🏠', 'Kira', 1050.0, '#6366F1'),
    ('Elektrik (E.ON)', '⚡', 'Elektrik', 110.0, '#F59E0B'),
    ('Su', '💧', 'Su', 40.0, '#06B6D4'),
    ('Doğalgaz', '🔥', 'Doğalgaz', 95.0, '#EF4444'),
    ('İnternet (Telekom)', '🌐', 'İnternet', 45.0, '#3B82F6'),
    ('Telefon (Vodafone)', '📱', 'Telefon', 25.0, '#F97316'),
    ('Krankenversicherung', '🏥', 'Sigorta', 200.0, '#10B981'),
    ('Disney+', '🏰', 'Eğlence', 9.0, '#113CCF'),
  ]),
};

// ── Screen ──

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _selectedCategory = 'Tümü';
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final allSubs = ref.watch(subscriptionProvider);
    final filtered = allSubs.where((s) {
      if (s.active != _showActive) return false;
      if (_selectedCategory != 'Tümü' && s.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    final activeSubs = allSubs.where((s) => s.active).toList();
    final totalMonthly =
        activeSubs.fold<double>(0, (sum, s) => sum + s.monthlyAmount);
    final totalYearly = totalMonthly * 12;

    const indigo = Color(0xFF6366F1);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 214,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0F),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D0D1A), Color(0xFF1A1035)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(bottom: BorderSide(color: indigo.withAlpha(30), width: 0.5)),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.subscriptions_outlined, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ev Giderleri',
                                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                                Text('Kira, faturalar ve abonelikler',
                                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Summary cards
                        Row(
                          children: [
                            Expanded(child: _SummaryCard(label: 'Aylık', value: '$_cur${totalMonthly.toStringAsFixed(0)}', icon: '📅')),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryCard(label: 'Yıllık', value: '$_cur${totalYearly.toStringAsFixed(0)}', icon: '📆')),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryCard(label: 'Aktif', value: '${activeSubs.length}', icon: '✅')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filter row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  // Active / Passive toggle
                  Row(
                    children: [
                      _ToggleChip(
                        label: '✅ Aktif (${allSubs.where((s) => s.active).length})',
                        active: _showActive,
                        onTap: () => setState(() => _showActive = true),
                      ),
                      const SizedBox(width: 8),
                      _ToggleChip(
                        label: '⏸ Pasif (${allSubs.where((s) => !s.active).length})',
                        active: !_showActive,
                        onTap: () => setState(() => _showActive = false),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showCountryPresets,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6)
                            ]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.public, size: 14, color: Colors.white),
                              SizedBox(width: 5),
                              Text('Ülke şablonu',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Category filter
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final sel = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF667EEA)
                                  : Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(cat,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white
                                        : const Color(0xFF6B7280))),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stripe banner (inactive)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6772E5).withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF6772E5).withAlpha(40)),
                ),
                child: const Row(
                  children: [
                    Text('💳', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Stripe ödeme sistemi yakında aktif olacak — aboneliklerinizi buradan yönetebileceksiniz.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6772E5),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Subscription list
          filtered.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📱', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Abonelik bulunamadı\n+ butonuna dokun',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _SubCard(
                      sub: filtered[i],
                      onToggle: () => ref
                          .read(subscriptionProvider.notifier)
                          .toggle(filtered[i].id),
                      onDelete: () => ref
                          .read(subscriptionProvider.notifier)
                          .delete(filtered[i].id),
                    ),
                    childCount: filtered.length,
                  ),
                ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: const Color(0xFF667EEA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Gider Ekle',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showCountryPresets() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('Ülke gider şablonu ekle',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Text(
                    'Seçtiğin ülkenin tipik hane giderleri listeye eklenir. Tutarları sonradan düzenleyebilirsin.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              ),
              ..._countryExpenses.entries.map((e) {
                final (label, items) = e.value;
                final total = items.fold<double>(0, (s, x) => s + x.$4);
                return ListTile(
                  title: Text(label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: Text('${items.length} gider · ~${total.toStringAsFixed(0)} / ay',
                      style: const TextStyle(color: Color(0xFF6B7280))),
                  trailing: const Icon(Icons.add_circle,
                      color: Color(0xFF8B5CF6)),
                  onTap: () {
                    final notifier =
                        ref.read(subscriptionProvider.notifier);
                    final now = DateTime.now();
                    final next = DateFormat('yyyy-MM-dd')
                        .format(DateTime(now.year, now.month + 1, 1));
                    for (final x in items) {
                      notifier.add(Subscription(
                        id: 'exp_${DateTime.now().microsecondsSinceEpoch}_${x.$1.hashCode}',
                        name: x.$1,
                        emoji: x.$2,
                        amount: x.$4,
                        cycle: BillingCycle.monthly,
                        nextBilling: next,
                        category: x.$3,
                        color: x.$5,
                      ));
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('$label giderleri eklendi'),
                        behavior: SnackBarBehavior.floating));
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSheet() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedEmoji = '📱';
    String selectedCategory = 'Diğer';
    String selectedColor = '#6C63FF';
    BillingCycle cycle = BillingCycle.monthly;
    int? selectedPreset;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF13131A),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('🧾 Gider Ekle',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 14),

                // Popular presets grid
                const Text('Sık Kullanılan Giderler',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularServices.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final (name, emoji, cat, color) =
                          _popularServices[i];
                      final sel = selectedPreset == i;
                      return GestureDetector(
                        onTap: () {
                          setSt(() {
                            selectedPreset = i;
                            selectedEmoji = emoji;
                            selectedCategory = cat;
                            selectedColor = color;
                            if (name != 'Diğer') {
                              nameCtrl.text = name;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 68,
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF667EEA).withAlpha(20)
                                : Colors.grey.withAlpha(12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF667EEA)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? const Color(0xFF667EEA)
                                        : const Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Name field
                _InputField(
                    controller: nameCtrl, label: 'Servis adı'),
                const SizedBox(height: 10),

                // Amount + cycle row
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: amountCtrl,
                        label: 'Tutar ($_cur)',
                        keyboard: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Billing cycle toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CycleBtn(
                            label: 'Aylık',
                            active: cycle == BillingCycle.monthly,
                            onTap: () => setSt(
                                () => cycle = BillingCycle.monthly),
                          ),
                          _CycleBtn(
                            label: 'Yıllık',
                            active: cycle == BillingCycle.yearly,
                            onTap: () => setSt(
                                () => cycle = BillingCycle.yearly),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Submit
                GestureDetector(
                  onTap: () {
                    final name = nameCtrl.text.trim();
                    final amount = double.tryParse(
                            amountCtrl.text.trim().replaceAll(',', '.')) ??
                        0;
                    if (name.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Lütfen servis adı ve geçerli bir tutar girin')),
                      );
                      return;
                    }

                    final nextBilling = DateFormat('dd.MM.yyyy').format(
                        DateTime.now().add(cycle == BillingCycle.monthly
                            ? const Duration(days: 30)
                            : const Duration(days: 365)));

                    ref.read(subscriptionProvider.notifier).add(
                          Subscription(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: name,
                            emoji: selectedEmoji,
                            amount: amount,
                            cycle: cycle,
                            nextBilling: nextBilling,
                            category: selectedCategory,
                            color: selectedColor,
                          ),
                        );
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF667EEA).withAlpha(60),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('Abonelik Ekle',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub Widgets ──

class _SubCard extends StatelessWidget {
  final Subscription sub;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _SubCard(
      {required this.sub, required this.onToggle, required this.onDelete});

  Color get _color {
    try {
      return Color(int.parse(sub.color.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Dismissible(
        key: Key(sub.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sub.active
                ? _color.withAlpha(10)
                : Colors.grey.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sub.active
                  ? _color.withAlpha(50)
                  : Colors.grey.withAlpha(30),
            ),
          ),
          child: Row(
            children: [
              // Emoji with color circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: sub.active
                      ? _color.withAlpha(25)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(sub.emoji,
                        style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.name,
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: sub.active
                                ? Colors.white
                                : const Color(0xFF9CA3AF))),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _color.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(sub.category,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: sub.active
                                      ? _color
                                      : Colors.grey)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sub.cycle == BillingCycle.monthly
                              ? 'Aylık'
                              : 'Yıllık',
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    Text('📅 Yenileme: ${sub.nextBilling}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_cur${sub.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color:
                            sub.active ? _color : Colors.grey),
                  ),
                  Text(
                    sub.cycle == BillingCycle.monthly
                        ? '/ay'
                        : '/yıl',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF9CA3AF)),
                  ),
                  if (sub.active)
                    Text(
                      '≈€${sub.monthlyAmount.toStringAsFixed(0)}/ay',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFB0B7C0)),
                    ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sub.active
                            ? Colors.green.withAlpha(20)
                            : Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sub.active ? '✓ Aktif' : 'Pasif',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: sub.active
                                ? Colors.green
                                : Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _SummaryCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF667EEA)
              : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboard;
  const _InputField({
    required this.controller,
    required this.label,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFF1A1A24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF667EEA), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _CycleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CycleBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF667EEA) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF9CA3AF))),
      ),
    );
  }
}
