import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/constants.dart';
import '../../../../core/supabase_client.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SafeZonesStep extends StatefulWidget {
  final String? familyId;
  final Function(List<Map<String, dynamic>> zones) onSaved;

  const SafeZonesStep({super.key, this.familyId, required this.onSaved});

  @override
  State<SafeZonesStep> createState() => _SafeZonesStepState();
}

class _SafeZonesStepState extends State<SafeZonesStep> {
  final List<Map<String, dynamic>> _zones = [];

  void _addZone() {
    showDialog(
      context: context,
      builder: (context) => _AddZoneDialog(
        onAdd: (zone) {
          setState(() => _zones.add(zone));
        },
      ),
    );
  }

  void _removeZone(int index) {
    setState(() => _zones.removeAt(index));
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    // Save to Supabase if familyId exists
    if (widget.familyId != null && _zones.isNotEmpty) {
      try {
        final client = SupabaseConfig.safeClient;
        if (client != null) {
          for (final zone in _zones) {
            await client.from('safe_zones').insert({
              'family_id': widget.familyId,
              'name': zone['name'],
              'type': zone['type'],
              'latitude': zone['latitude'],
              'longitude': zone['longitude'],
              'radius_meters': zone['radius_meters'],
              'address': zone['address'],
            });
          }
        }
      } catch (e) {
        debugPrint('Safe zones save error: $e');
      }
    }

    widget.onSaved(_zones);
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
                  'Güvenli Bölgeler',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Aileniz için güvenli bölgeler tanımlayın (isteğe bağlı)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _zones.length,
                  itemBuilder: (context, index) {
                    final zone = _zones[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          _iconForType(zone['type'] as String),
                          color: const Color(0xFF6366F1),
                        ),
                        title: Text(zone['name'] as String),
                        subtitle: Text('${zone['radius_meters']}m yarıçap'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => _removeZone(index),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addZone,
                  icon: const Icon(Icons.add_location_alt),
                  label: Text(AppLocalizations.of(context).bolgeEkle),
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

  IconData _iconForType(String type) {
    return switch (type) {
      'home' => Icons.home,
      'work' => Icons.work,
      'school' => Icons.school,
      _ => Icons.location_on,
    };
  }
}

class _AddZoneDialog extends StatefulWidget {
  final Function(Map<String, dynamic> zone) onAdd;

  const _AddZoneDialog({required this.onAdd});

  @override
  State<_AddZoneDialog> createState() => _AddZoneDialogState();
}

class _AddZoneDialogState extends State<_AddZoneDialog> {
  final _nameController = TextEditingController();
  String _type = 'home';
  double _radius = 100;

  void _add() {
    if (_nameController.text.trim().isEmpty) return;
    widget.onAdd({
      'name': _nameController.text.trim(),
      'type': _type,
      'latitude': 50.1109, // Default: Europe center
      'longitude': 8.6821,
      'radius_meters': _radius.round(),
      'address': '',
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).guvenliBolgeEkle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Bölge Adı'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Bölge Tipi'),
              items: [
                const DropdownMenuItem(value: 'home', child: Text('Ev')),
                DropdownMenuItem(value: 'work', child: Text(AppLocalizations.of(context).isLabel)),
                const DropdownMenuItem(value: 'school', child: Text('Okul')),
                DropdownMenuItem(value: 'custom', child: Text(AppLocalizations.of(context).ozel)),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            Text('Yarıçap: ${_radius.round()}m'),
            Slider(
              value: _radius,
              min: 50,
              max: 500,
              divisions: 9,
              label: '${_radius.round()}m',
              onChanged: (v) => setState(() => _radius = v),
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
