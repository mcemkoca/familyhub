import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../child/child_development_screen.dart' show childDevProvider;
import 'health_store.dart';

/// Ekran 4 — Çocuk Sağlığı (büyüme, aşı, kontroller).
class CocukSaglikScreen extends ConsumerStatefulWidget {
  const CocukSaglikScreen({super.key});

  @override
  ConsumerState<CocukSaglikScreen> createState() => _CocukSaglikScreenState();
}

class _CocukSaglikScreenState extends ConsumerState<CocukSaglikScreen> {
  @override
  Widget build(BuildContext context) {
    final children = ref.watch(childDevProvider);
    final name = children.isNotEmpty ? children.first.name : 'Çocuk';
    final ageLabel = children.isNotEmpty ? children.first.ageLabel : '';
    final childId = children.isNotEmpty ? children.first.id : 'default';
    final g = HealthStore.childGrowth(childId);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            const HealthHeader(
              title: 'Çocuk Sağlığı',
              subtitle: 'Çocuk için sağlık takibi',
              icon: Icons.child_care_rounded,
              gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              showBack: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _childCard(name, ageLabel),
                  const SizedBox(height: 18),
                  const Text('Sağlık Özeti',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _statCard(
                              'Boy',
                              g.height > 0 ? '${g.height.round()} cm' : '— ekle',
                              Icons.straighten,
                              const Color(0xFF22C55E),
                              () => _editGrowth(childId, g))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(
                              'Kilo',
                              g.weight > 0
                                  ? '${g.weight.toStringAsFixed(1)} kg'
                                  : '— ekle',
                              Icons.monitor_weight,
                              const Color(0xFFF59E0B),
                              () => _editGrowth(childId, g))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _statCard('Aşı Durumu', 'Güncel',
                              Icons.verified_user, const Color(0xFF3B82F6), null,
                              valueColor: const Color(0xFF22C55E))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard('Gelişim Takibi', 'Yaşına uygun',
                              Icons.star, const Color(0xFF8B5CF6), null,
                              valueColor: const Color(0xFFA855F7))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    'Yaklaşanlar',
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Yaklaşan randevu yok',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _vaccineCard(),
                  const SizedBox(height: 16),
                  _tipCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGrowth(
      String childId, ({double height, double weight}) g) async {
    // Boşsa düzenlemeye makul bir başlangıçtan başla.
    double h = g.height > 0 ? g.height : 100, w = g.weight > 0 ? g.weight : 16;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF13131A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Boy & Kilo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              _adjustRow('Boy (cm)', h.round().toString(),
                  () => setSheet(() => h = (h - 1).clamp(30, 200)),
                  () => setSheet(() => h = (h + 1).clamp(30, 200))),
              const SizedBox(height: 12),
              _adjustRow('Kilo (kg)', w.toStringAsFixed(1),
                  () => setSheet(() => w = (w - 0.1).clamp(2, 120)),
                  () => setSheet(() => w = (w + 0.1).clamp(2, 120))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await HealthStore.setChildGrowth(childId, h, w);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Kaydet',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adjustRow(String label, String value, VoidCallback dec, VoidCallback inc) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 15))),
        _sb(Icons.remove, dec),
        SizedBox(
            width: 70,
            child: Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800))),
        _sb(Icons.add, inc),
      ],
    );
  }

  Widget _sb(IconData ic, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(ic, color: const Color(0xFF3B82F6), size: 22),
        ),
      );

  Widget _childCard(String name, String ageLabel) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A1330), Color(0xFF130E24)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x333B82F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.child_care, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                Text(ageLabel,
                    style:
                        const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
              ],
            ),
          ),
          const Text('💙', style: TextStyle(fontSize: 34)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      VoidCallback? onTap,
      {Color? valueColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _vaccineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1414B8A6)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vaccines, color: Color(0xFF14B8A6), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aşı Takvimi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Aşı takvimini görüntüleyin ve takip edin.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Text('Gör',
                    style: TextStyle(
                        color: Color(0xFF14B8A6),
                        fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right, color: Color(0xFF14B8A6), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x223B82F6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: Color(0xFF3B82F6), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bugünkü İpucu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text(
                    'Bol su içmek, çocukların hem fiziksel hem de zihinsel gelişimi için çok önemlidir. Gün içinde su içmeyi alışkanlık haline getirmeyi unutmayın.',
                    style: TextStyle(
                        color: Color(0xFFD1D5DB), fontSize: 13.5, height: 1.45)),
              ],
            ),
          ),
          Text('💧', style: TextStyle(fontSize: 30)),
        ],
      ),
    );
  }
}
