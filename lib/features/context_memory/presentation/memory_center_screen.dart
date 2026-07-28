/// Context Memory — Faz 8: Hafıza Merkezi ekranı.
///
/// Kullanıcı FamilyHub AI'ın kendisi ve ailesi hakkında ne hatırladığını
/// görür, doğrular, reddeder, sabitler ve siler (GDPR şeffaflık + kontrol).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/settings/screen_header.dart';
import '../../../services/auth_service.dart';
import '../application/memory_providers.dart';
import '../domain/memory_enums.dart';
import '../domain/memory_record.dart';
import '../infrastructure/memory_repository.dart';

class MemoryCenterScreen extends ConsumerWidget {
  const MemoryCenterScreen({super.key});

  static const _bg = Color(0xFF0A0A0F);
  static const _card = Color(0xFF15151F);
  static const _muted = Color(0xFF9CA3AF);
  static const _dim = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(memoryTabProvider);
    final records = ref.watch(filteredMemoriesProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: ScreenHeader(
        title: 'FamilyHub Hafızası',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'FamilyHub AI’ın sizin ve aileniz hakkında hatırlamasına izin '
              'verdiğiniz bilgileri yönetin.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ),
          _SearchField(
            onChanged: (v) =>
                ref.read(memorySearchProvider.notifier).state = v,
          ),
          _TabBar(
            selected: tab,
            onSelect: (t) => ref.read(memoryTabProvider.notifier).state = t,
          ),
          Expanded(
            child: records.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _MemoryCard(
                      record: records[i],
                      onChanged: () => ref.invalidate(memoryRecordsProvider),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Hafızada ara…',
          hintStyle: const TextStyle(color: MemoryCenterScreen._dim),
          prefixIcon: const Icon(Icons.search, color: MemoryCenterScreen._dim),
          filled: true,
          fillColor: MemoryCenterScreen._card,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final MemoryTab selected;
  final ValueChanged<MemoryTab> onSelect;
  const _TabBar({required this.selected, required this.onSelect});

  static const _labels = {
    MemoryTab.mine: 'Benim',
    MemoryTab.family: 'Aile',
    MemoryTab.children: 'Çocuklar',
    MemoryTab.preferences: 'Tercihler',
    MemoryTab.derived: 'AI Çıkarımları',
    MemoryTab.archive: 'Arşiv',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: MemoryTab.values.map((t) {
          final on = t == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_labels[t]!),
              selected: on,
              onSelected: (_) => onSelect(t),
              backgroundColor: MemoryCenterScreen._card,
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: on ? Colors.white : MemoryCenterScreen._muted,
                fontSize: 12,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_outlined,
                size: 48, color: MemoryCenterScreen._dim),
            SizedBox(height: 12),
            Text(
              'Burada henüz kayıt yok',
              style: TextStyle(color: MemoryCenterScreen._muted, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'FamilyHub AI ile konuştukça ve uygulamayı kullandıkça, '
              'izin verdiğiniz bilgiler burada görünür.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MemoryCenterScreen._dim, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek memory kartı — kaynak, güven ve kapsam şeffaf gösterilir.
class _MemoryCard extends StatelessWidget {
  final MemoryRecord record;
  final VoidCallback onChanged;
  const _MemoryCard({required this.record, required this.onChanged});

  String get _sourceLabel => switch (record.sourceType) {
        MemorySourceType.userCorrection => 'Düzeltmeniz',
        MemorySourceType.userMessage => 'Söylediğiniz',
        MemorySourceType.aiDerived => 'AI çıkarımı',
        MemorySourceType.applicationEvent => 'Uygulama olayı',
        MemorySourceType.moduleRecord => 'Kayıt',
        MemorySourceType.profile => 'Profil',
        MemorySourceType.familyMember => 'Aile üyesi',
        MemorySourceType.importedData => 'İçe aktarım',
        MemorySourceType.externalSource => 'Dış kaynak',
      };

  String get _scopeLabel => switch (record.scope) {
        MemoryScope.userPrivate => 'Yalnızca siz',
        MemoryScope.memberPrivate => 'Üye özel',
        MemoryScope.childPrivate => 'Çocuk',
        MemoryScope.familyShared => 'Aile',
        MemoryScope.module => 'Modül',
        MemoryScope.deviceLocal => 'Bu cihaz',
        MemoryScope.session => 'Oturum',
      };

  bool get _needsReview =>
      record.sourceType == MemorySourceType.aiDerived ||
      record.status == MemoryStatus.disputed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MemoryCenterScreen._card,
        borderRadius: BorderRadius.circular(14),
        border: record.status == MemoryStatus.disputed
            ? Border.all(color: const Color(0xFFB45309), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (record.pinned)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.push_pin, size: 14, color: Color(0xFF6366F1)),
                ),
              Expanded(
                child: Text(
                  record.title.isEmpty ? record.key : record.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
              _Chip(text: record.module),
            ],
          ),
          const SizedBox(height: 6),
          Text(record.content,
              style: const TextStyle(
                  color: MemoryCenterScreen._muted, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(text: _sourceLabel, warn: _needsReview),
              _Chip(text: _scopeLabel),
              if (record.sensitivity.requiresExplicitConsent)
                const _Chip(text: 'Hassas', warn: true),
              if (record.status == MemoryStatus.disputed)
                const _Chip(text: 'Çelişkili', warn: true),
              _Chip(text: record.updatedAt.toIso8601String().split('T').first),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (_needsReview) ...[
                _Action(
                  icon: Icons.check_circle_outline,
                  label: 'Doğrula',
                  onTap: () async {
                    await MemoryRepository.instance.save(
                      record.copyWith(
                        confirmed: true,
                        status: MemoryStatus.active,
                        sourceType: MemorySourceType.userCorrection,
                        updatedAt: DateTime.now(),
                        syncState: MemorySyncState.pendingUpdate,
                      ),
                    );
                    onChanged();
                  },
                ),
                _Action(
                  icon: Icons.cancel_outlined,
                  label: 'Reddet',
                  onTap: () async {
                    await MemoryRepository.instance.save(
                      record.copyWith(
                        status: MemoryStatus.rejected,
                        updatedAt: DateTime.now(),
                        syncState: MemorySyncState.pendingUpdate,
                      ),
                    );
                    onChanged();
                  },
                ),
              ],
              _Action(
                icon: record.pinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                label: record.pinned ? 'Sabit' : 'Sabitle',
                onTap: () async {
                  await MemoryRepository.instance.save(
                    record.copyWith(
                      pinned: !record.pinned,
                      updatedAt: DateTime.now(),
                      syncState: MemorySyncState.pendingUpdate,
                    ),
                  );
                  onChanged();
                },
              ),
              const Spacer(),
              _Action(
                icon: Icons.delete_outline,
                label: 'Sil',
                danger: true,
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: MemoryCenterScreen._card,
                      title: const Text('Bu bilgiyi sil',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      content: const Text(
                        'FamilyHub AI bu bilgiyi artık kullanmayacak.',
                        style: TextStyle(color: MemoryCenterScreen._muted),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Vazgeç')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sil',
                                style: TextStyle(color: Color(0xFFEF4444)))),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  await MemoryRepository.instance
                      .softDelete(record.id, now: DateTime.now());
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool warn;
  const _Chip({required this.text, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warn
            ? const Color(0xFFB45309).withAlpha(40)
            : Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: warn ? const Color(0xFFFBBF24) : MemoryCenterScreen._dim,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        danger ? const Color(0xFFEF4444) : MemoryCenterScreen._muted;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Oturum yoksa hafıza gösterilmez (izolasyon).
bool memoryCenterAvailable() => AuthService.currentUserId != null;
