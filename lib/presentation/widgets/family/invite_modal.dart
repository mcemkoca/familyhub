import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class InviteModal extends StatefulWidget {
  final VoidCallback onClose;

  const InviteModal({super.key, required this.onClose});

  @override
  State<InviteModal> createState() => _InviteModalState();
}

class _InviteModalState extends State<InviteModal> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  String? _code;
  DateTime? _expiry;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  void _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    _code = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    _expiry = DateTime.now().add(const Duration(days: 7));
    setState(() {});
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kod kopyalandı')),
    );
  }

  void _shareCode() {
    if (_code == null) return;
    SharePlus.instance.share(
      ShareParams(text: 'FamilyHub\'a katıl! Davet kodun: $_code\nhttps://familyhub.app/join/$_code'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _expiry != null
        ? _expiry!.difference(DateTime.now()).inDays
        : 7;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withAlpha(40),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ailem\'ne Davet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Yeni üyeleri davet etmek için kod oluştur',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Code
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0A0A0F)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x1EFFFFFF)
                            : const Color(0x1EFFFFFF),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _code ?? '...',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$daysLeft gün kaldı',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.copy,
                          label: 'Kopyala',
                          onTap: _copyCode,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.share,
                          label: 'Paylaş',
                          onTap: _shareCode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _shareCode,
                      icon: const Icon(Icons.chat_bubble, size: 20),
                      label: const Text('Paylaş'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text(
                      'Kapat',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0A0A0F)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
