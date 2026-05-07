import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as phone_contacts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/constants.dart';
import '../../../repositories/contacts_repository.dart';
import '../../../services/auth_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'other';
  List<FamilyContact> _contacts = [];
  List<FamilyContact> _filtered = [];
  StreamSubscription<List<FamilyContact>>? _sub;
  bool _isLoading = false;

  final _types = [
    {'key': 'family', 'label': 'Aile', 'icon': Icons.family_restroom},
    {'key': 'friend', 'label': 'Arkadaş', 'icon': Icons.people},
    {'key': 'work', 'label': 'İş', 'icon': Icons.work},
    {'key': 'school', 'label': 'Okul', 'icon': Icons.school},
    {'key': 'doctor', 'label': 'Doktor', 'icon': Icons.local_hospital},
    {'key': 'emergency', 'label': 'Acil', 'icon': Icons.emergency},
    {'key': 'other', 'label': 'Diğer', 'icon': Icons.person},
  ];

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    final profile = await AuthService.safeClient
        ?.from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    return profile?['family_id'] as String?;
  }

  void _subscribe() async {
    final familyId = await _getFamilyId();
    if (familyId == null) return;
    _sub?.cancel();
    _sub = ContactsRepository().watchContacts(familyId).listen((contacts) {
      setState(() {
        _contacts = contacts;
        _filter();
      });
    }, onError: (e) => debugPrint('Contacts stream error: $e'));
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _contacts
          : _contacts
                .where(
                  (c) =>
                      c.name.toLowerCase().contains(q) ||
                      (c.phone?.toLowerCase().contains(q) ?? false),
                )
                .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _subscribe();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _importFromPhone() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rehber izni gerekli')));
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final phoneContacts = await phone_contacts.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      final familyId = await _getFamilyId();
      if (familyId == null) return;
      final repo = ContactsRepository();
      int imported = 0;
      for (final pc in phoneContacts.take(50)) {
        final phone = pc.phones.isNotEmpty ? pc.phones.first.number : null;
        final email = pc.emails.isNotEmpty ? pc.emails.first.address : null;
        if (phone == null && email == null) continue;
        await repo.createContact(
          familyId: familyId,
          name: pc.displayName,
          phone: phone,
          email: email,
          type: 'other',
        );
        imported++;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$imported kişi içe aktarıldı')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İçe aktarma hatası: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddSheet({FamilyContact? contact}) {
    final isEdit = contact != null;
    _nameController.text = contact?.name ?? '';
    _phoneController.text = contact?.phone ?? '';
    _emailController.text = contact?.email ?? '';
    _notesController.text = contact?.notes ?? '';
    _selectedType = contact?.type ?? 'other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Kişiyi Düzenle' : 'Yeni Kişi',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notlar'),
                ),
                const SizedBox(height: 12),
                Text('Tür', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _types.map((t) {
                    final selected = _selectedType == t['key'];
                    return ChoiceChip(
                      avatar: Icon(t['icon'] as IconData, size: 18),
                      label: Text(t['label'] as String),
                      selected: selected,
                      onSelected: (_) => setModalState(
                        () => _selectedType = t['key'] as String,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isEmpty) return;
                      final familyId = await _getFamilyId();
                      if (familyId == null) return;
                      final repo = ContactsRepository();
                      if (isEdit) {
                        await repo.updateContact(contact.id, {
                          'name': _nameController.text,
                          'phone': _phoneController.text.isEmpty
                              ? null
                              : _phoneController.text,
                          'email': _emailController.text.isEmpty
                              ? null
                              : _emailController.text,
                          'type': _selectedType,
                          'notes': _notesController.text.isEmpty
                              ? null
                              : _notesController.text,
                        });
                      } else {
                        await repo.createContact(
                          familyId: familyId,
                          name: _nameController.text,
                          phone: _phoneController.text.isEmpty
                              ? null
                              : _phoneController.text,
                          email: _emailController.text.isEmpty
                              ? null
                              : _emailController.text,
                          type: _selectedType,
                          notes: _notesController.text.isEmpty
                              ? null
                              : _notesController.text,
                        );
                      }
                      if (!context.mounted) return;
                      _nameController.clear();
                      _phoneController.clear();
                      _emailController.clear();
                      _notesController.clear();
                      _selectedType = 'other';
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cobalt,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(isEdit ? 'Kaydet' : 'Ekle'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteContact(FamilyContact contact) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).kisiyiSil),
        content: Text('${contact.name} silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ContactsRepository().deleteContact(contact.id);
      HapticFeedback.mediumImpact();
    }
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'family' => Icons.family_restroom,
      'friend' => Icons.people,
      'work' => Icons.work,
      'school' => Icons.school,
      'doctor' => Icons.local_hospital,
      'emergency' => Icons.emergency,
      _ => Icons.person,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aile Rehberi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Telefondan İçe Aktar',
            onPressed: _isLoading ? null : _importFromPhone,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contacts,
                          size: 64,
                          color: AppColors.lightGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz kişi yok',
                          style: TextStyle(fontSize: 18, color: AppColors.gray),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final c = _filtered[index];
                      return Dismissible(
                        key: Key(c.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteContact(c),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.error,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.cobalt.withAlpha(30),
                              child: Icon(
                                _typeIcon(c.type),
                                color: AppColors.cobalt,
                              ),
                            ),
                            title: Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: c.phone != null ? Text(c.phone!) : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showAddSheet(contact: c),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _deleteContact(c),
                                ),
                              ],
                            ),
                            onTap: () => _showAddSheet(contact: c),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(),
        backgroundColor: AppColors.cobalt,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
