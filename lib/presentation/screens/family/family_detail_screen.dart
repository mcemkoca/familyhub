import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/models/family_info.dart';
import '../../../services/auth_service.dart';
import '../../../services/family_service.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class FamilyDetailScreen extends StatefulWidget {
  final String? familyId;

  const FamilyDetailScreen({super.key, this.familyId});

  @override
  State<FamilyDetailScreen> createState() => _FamilyDetailScreenState();
}

class _FamilyDetailScreenState extends State<FamilyDetailScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  FamilyInfo? _familyInfo;
  List<FamilyHistory> _history = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _familyId;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _foundedDate;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _resolveFamilyId();
  }

  Future<void> _resolveFamilyId() async {
    if (widget.familyId != null) {
      _familyId = widget.familyId;
    } else {
      final userId = AuthService.currentUserId;
      if (userId != null) {
        final client = SupabaseConfig.safeClient;
        if (client != null) {
          final profile = await client
              .from('profiles')
              .select('family_id')
              .eq('id', userId)
              .maybeSingle();
          _familyId = profile?['family_id'] as String?;
        }
      }
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_familyId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final service = await FamilyService.create();
      final info = await service.getFamilyInfo(_familyId!);
      final history = await service.getFamilyHistory(_familyId!);

      if (mounted) {
        setState(() {
          _familyInfo = info;
          _history = history;
          _nameController.text = info?.name ?? '';
          _descriptionController.text = info?.description ?? '';
          _foundedDate = info?.foundedDate;
          _photoUrl = info?.photoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Family detail load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null || _familyId == null) return;

    setState(() => _isSaving = true);
    try {
      final service = await FamilyService.create();
      final url = await service.uploadFamilyPhoto(
        _familyId!,
        File(picked.path),
      );
      setState(() => _photoUrl = url);

      await service.updateFamilyInfo(
        familyId: _familyId!,
        photoUrl: url,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aile fotoğrafı güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yüklenemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveInfo() async {
    HapticFeedback.mediumImpact();
    if (_familyId == null) return;

    setState(() => _isSaving = true);
    try {
      final service = await FamilyService.create();
      await service.updateFamilyInfo(
        familyId: _familyId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        foundedDate: _foundedDate,
      );

      final info = await service.getFamilyInfo(_familyId!);
      if (mounted) {
        setState(() {
          _familyInfo = info;
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aile bilgileri kaydedildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFoundedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _foundedDate = picked);
    }
  }

  Future<void> _addHistory() async {
    if (_familyId == null) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHistorySheet(familyId: _familyId!),
    );
    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _deleteHistory(String historyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).delete),
        content: const Text('Bu anı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final service = await FamilyService.create();
      await service.deleteFamilyHistory(historyId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anı silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silinemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool get _isAdminOrParent {
    // Simplified: we could check family_members role, but for UX
    // we allow editing if the user created the family
    return _familyInfo?.createdBy == AuthService.currentUserId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0A0A0F);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: ScreenHeader(
          title: 'Aile Detayları',
          showBack: true,
          onBack: () => Navigator.pop(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_familyId == null || _familyInfo == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: ScreenHeader(
          title: 'Aile Detayları',
          showBack: true,
          onBack: () => Navigator.pop(context),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context).aileBilgisiBulunamadi),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Aile Detayları',
        showBack: true,
        onBack: () => Navigator.pop(context),
        rightAction: _isEditing
            ? TextButton(
                onPressed: _isSaving ? null : _saveInfo,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6366F1),
                        ),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )
            : (_isAdminOrParent
                ? TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text(
                      'Düzenle',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo
                  _buildPhotoSection(isDark),
                  const SizedBox(height: 20),
                  // Info Card
                  _buildInfoCard(isDark),
                  const SizedBox(height: 24),
                  // History Header
                  const Text(
                    'AİLE TARİHÇESİ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (_history.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyHistory(),
              ),
            )
          else
            SliverList.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _HistoryCard(
                    history: item,
                    onDelete: _isAdminOrParent ? () => _deleteHistory(item.id) : null,
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHistory,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Anı Ekle', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPhotoSection(bool isDark) {
    return GestureDetector(
      onTap: _isEditing ? _pickPhoto : null,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(20),
              image: _photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _photoUrl == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        size: 48,
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aile Fotoğrafı',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Değiştir',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTextField(
              label: 'Aile Adı',
              controller: _nameController,
              icon: Icons.family_restroom_outlined,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Açıklama',
              controller: _descriptionController,
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickFoundedDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kuruluş Tarihi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _foundedDate != null
                                ? DateFormat('dd MMMM yyyy', 'tr').format(_foundedDate!)
                                : 'Seçilmedi',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _familyInfo!.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE5E7EB),
            ),
          ),
          if (_familyInfo!.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              _familyInfo!.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          if (_familyInfo!.foundedDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kuruluş: ${DateFormat('dd MMMM yyyy', 'tr').format(_familyInfo!.foundedDate!)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                '${_history.length} anı kaydedildi',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFF6B7280),
            ),
            filled: true,
            fillColor: const Color(0xFF0A0A0F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final FamilyHistory history;
  final VoidCallback? onDelete;

  const _HistoryCard({required this.history, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: history.typeColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: history.typeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        history.typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: history.typeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      history.eventDate != null
                          ? DateFormat('dd.MM.yyyy').format(history.eventDate!)
                          : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  history.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                if (history.content?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    history.content!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: Color(0xFF6B7280),
          ),
          SizedBox(height: 12),
          Text(
            'Henüz bir aile anısı eklenmemiş',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tatiller, doğum günleri veya özel anları ekleyin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddHistorySheet extends StatefulWidget {
  final String familyId;

  const _AddHistorySheet({required this.familyId});

  @override
  State<_AddHistorySheet> createState() => _AddHistorySheetState();
}

class _AddHistorySheetState extends State<_AddHistorySheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _eventDate = DateTime.now();
  String _type = 'memory';
  bool _saving = false;

  final _types = [
    ('memory', 'Anı'),
    ('milestone', 'Kilometre Taşı'),
    ('trip', 'Seyahat'),
    ('birth', 'Doğum'),
    ('anniversary', 'Yıldönümü'),
    ('other', 'Diğer'),
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      final service = await FamilyService.create();
      await service.addFamilyHistory(
        familyId: widget.familyId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        eventDate: _eventDate,
        type: _type,
      );
      if (mounted) Navigator.pop(context, {'saved': true});
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eklenemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Anı Ekle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE5E7EB),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Başlık',
                  filled: true,
                  fillColor: const Color(0xFF13131A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Detay (isteğe bağlı)',
                  filled: true,
                  fillColor: const Color(0xFF13131A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMMM yyyy', 'tr').format(_eventDate),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((type) {
                  final selected = _type == type.$1;
                  return ChoiceChip(
                    label: Text(type.$2),
                    selected: selected,
                    selectedColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : (const Color(0xFFE5E7EB)),
                    ),
                    onSelected: (_) => setState(() => _type = type.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
