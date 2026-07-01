import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

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

  Future<Box> get _box async => Hive.isBoxOpen(_boxName)
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
  ('Netflix', '🎬', 'Eğlence', '#E50914'),
  ('Spotify', '🎵', 'Müzik', '#1DB954'),
  ('YouTube Premium', '📺', 'Eğlence', '#FF0000'),
  ('Apple TV+', '🍎', 'Eğlence', '#000000'),
  ('Disney+', '🏰', 'Eğlence', '#113CCF'),
  ('Amazon Prime', '📦', 'Alışveriş', '#FF9900'),
  ('iCloud', '☁️', 'Depolama', '#007AFF'),
  ('Google One', '🔵', 'Depolama', '#4285F4'),
  ('Microsoft 365', '💼', 'Üretkenlik', '#0078D4'),
  ('Canva Pro', '🎨', 'Tasarım', '#8B3DFF'),
  ('ChatGPT Plus', '🤖', 'AI', '#10A37F'),
  ('Duolingo Plus', '🦜', 'Eğitim', '#58CC02'),
  ('Diğer', '📱', 'Diğer', '#6C63FF'),
];

const _categories = [
  'Tümü', 'Eğlence', 'Müzik', 'Depolama', 'Üretkenlik',
  'Alışveriş', 'Eğitim', 'AI', 'Tasarım', 'Diğer'
];

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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Text('📱 Abonelik Takibi',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        const Text('Tüm dijital abonelikleriniz',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 16),
                        // Summary cards
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                label: 'Aylık Toplam',
                                value:
                                    '₺${totalMonthly.toStringAsFixed(0)}',
                                icon: '📅',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryCard(
                                label: 'Yıllık Toplam',
                                value:
                                    '₺${totalYearly.toStringAsFixed(0)}',
                                icon: '📆',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryCard(
                                label: 'Aktif',
                                value: '${activeSubs.length} adet',
                                icon: '✅',
                              ),
                            ),
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
                                    fontSize: 11,
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
                            fontSize: 11,
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
        label: const Text('Abonelik Ekle',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
              color: Colors.white,
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
                      color: Colors.grey.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('📱 Abonelik Ekle',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),

                // Popular services grid
                const Text('Popüler Servisler',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280))),
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
                                    fontSize: 9,
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
                        label: 'Ücret (₺)',
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
                    final amount =
                        double.tryParse(amountCtrl.text) ?? 0;
                    if (name.isEmpty || amount <= 0) return;

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
                            fontWeight: FontWeight.w800,
                            color: sub.active
                                ? Colors.black87
                                : Colors.grey)),
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
                                  fontSize: 9,
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
                              fontSize: 10,
                              color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    Text('📅 Yenileme: ${sub.nextBilling}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${sub.amount.toStringAsFixed(0)}',
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
                        fontSize: 10,
                        color: Color(0xFF9CA3AF)),
                  ),
                  if (sub.active)
                    Text(
                      '≈₺${sub.monthlyAmount.toStringAsFixed(0)}/ay',
                      style: const TextStyle(
                          fontSize: 9,
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
                            fontSize: 9,
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
                  fontSize: 9,
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
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
