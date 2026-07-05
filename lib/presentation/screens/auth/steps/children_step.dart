import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/constants.dart';
import '../../../../core/supabase_client.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ChildrenStep extends StatefulWidget {
  final String? familyId;
  final Function(List<Map<String, dynamic>> children) onSaved;

  const ChildrenStep({super.key, this.familyId, required this.onSaved});

  @override
  State<ChildrenStep> createState() => _ChildrenStepState();
}

class _ChildrenStepState extends State<ChildrenStep> {
  final List<Map<String, dynamic>> _children = [];

  void _addChild() {
    showDialog(
      context: context,
      builder: (context) => _AddChildDialog(
        onAdd: (child) {
          setState(() => _children.add(child));
        },
      ),
    );
  }

  void _removeChild(int index) {
    setState(() => _children.removeAt(index));
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    if (widget.familyId != null && _children.isNotEmpty) {
      try {
        final client = SupabaseConfig.safeClient;
        if (client != null) {
          for (final child in _children) {
            await client.from('child_accounts').insert({
              'family_id': widget.familyId,
              'name': child['name'],
              'role': child['role'],
              'color': child['color'],
              'pin_hash': child['pin_hash'], // In real app, hash the PIN
              'can_send_messages': true,
              'can_view_budget': false,
              'can_approve_tasks': false,
            });
          }
        }
      } catch (e) {
        debugPrint('Children save error: $e');
      }
    }

    widget.onSaved(_children);
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çocuk Hesapları',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Çocuklarınızın hesaplarını ekleyin (isteğe bağlı)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final child = _children[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(
                            int.parse(
                              child['color'].toString().replaceFirst(
                                '#',
                                '0xFF',
                              ),
                            ),
                          ).withAlpha(255),
                          child: Text(
                            (child['name'] as String)[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(child['name'] as String),
                        subtitle: Text(_roleLabel(child['role'] as String)),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => _removeChild(index),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addChild,
                  icon: const Icon(Icons.person_add),
                  label: Text(AppLocalizations.of(context).cocukEkle),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'İleri',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'child' => 'Çocuk',
      'teen' => 'Genç',
      'baby' => 'Bebek',
      _ => role,
    };
  }
}

class _AddChildDialog extends StatefulWidget {
  final Function(Map<String, dynamic> child) onAdd;

  const _AddChildDialog({required this.onAdd});

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  String _role = 'child';
  Color _color = const Color(0xFF6366F1);

  final _colors = [
    const Color(0xFF6366F1),
    AppColors.green,
    AppColors.orange,
    const Color(0xFF8B5CF6),
    AppColors.red,
    const Color(0xFFEC4899),
  ];

  void _add() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).isimGirin)));
      return;
    }
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).pinEnAz4HaneOlmali)));
      return;
    }
    if (_pinController.text != _pinConfirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).pinlerEslesmiyor)));
      return;
    }

    widget.onAdd({
      'name': _nameController.text.trim(),
      'role': _role,
      'color': '#${_color.toARGB32().toRadixString(16).substring(2)}',
      'pin_hash': _pinController.text, // In production: hash this
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).cocukEkle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'İsim'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: [
                DropdownMenuItem(value: 'child', child: Text(AppLocalizations.of(context).child)),
                DropdownMenuItem(value: 'teen', child: Text(AppLocalizations.of(context).genc)),
                const DropdownMenuItem(value: 'baby', child: Text('Bebek')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN (4-6 hane)',
                prefixIcon: Icon(Icons.pin),
              ),
              maxLength: 6,
            ),
            TextField(
              controller: _pinConfirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN Tekrar',
                prefixIcon: Icon(Icons.pin),
              ),
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _colors.map((c) {
                final selected = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        TextButton(onPressed: _add, child: Text(AppLocalizations.of(context).add)),
      ],
    );
  }
}
