import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// file_picker removed — using image_picker only
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../repositories/document_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/permission_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  List<FamilyDocument> _documents = [];
  StreamSubscription<List<FamilyDocument>>? _sub;
  bool _isUploading = false;
  final _textRecognizer = TextRecognizer();
  DocumentCategory? _filterCategory; // null = tümü

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return DocumentRepository.localFamilyId;
    try {
      final profile = await AuthService.safeClient
          ?.from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      return (profile?['family_id'] as String?) ??
          DocumentRepository.localFamilyId;
    } catch (_) {
      return DocumentRepository.localFamilyId;
    }
  }

  void _subscribe() async {
    final familyId = await _getFamilyId();
    // Yerel mod — Hive'daki belgeleri yükle (realtime yok).
    if (familyId == DocumentRepository.localFamilyId) {
      if (mounted) {
        setState(() => _documents = DocumentRepository().getLocalDocuments());
      }
      return;
    }
    _sub?.cancel();
    _sub = DocumentRepository()
        .watchDocuments(familyId!)
        .listen(
          (docs) => setState(() => _documents = docs),
          onError: (e) => debugPrint('Documents stream error: $e'),
        );
  }

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _textRecognizer.close();
    super.dispose();
  }

  Future<String?> _runOcr(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final result = await _textRecognizer.processImage(inputImage);
      return result.text;
    } catch (e) {
      debugPrint('OCR error: $e');
      return null;
    }
  }

  /// Shows dialog to collect document title, category, expiry date.
  Future<({String title, DocumentCategory category, DateTime? expiry})?> _showMetadataDialog(String defaultName) async {
    final titleCtrl = TextEditingController(text: defaultName);
    DocumentCategory category = DocumentCategory.other;
    DateTime? expiry;

    return showDialog<({String title, DocumentCategory category, DateTime? expiry})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF13131A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x1EFFFFFF), width: 0.5),
          ),
          title: const Text('Belge Bilgileri',
              style: TextStyle(color: Color(0xFFE5E7EB))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Color(0xFFE5E7EB)),
                  decoration: InputDecoration(
                    labelText: 'Belge Adı',
                    labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0x1AFFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Category
                const Text('Kategori',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DocumentCategory.values.map((c) {
                    final selected = category == c;
                    return GestureDetector(
                      onTap: () => setLocal(() => category = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF6366F1)
                              : const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF6366F1)
                                : const Color(0x1EFFFFFF),
                          ),
                        ),
                        child: Text(
                          c.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : const Color(0xFF9CA3AF),
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Expiry date
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expiry ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                      builder: (_, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF6366F1),
                            surface: Color(0xFF13131A),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setLocal(() => expiry = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: expiry != null
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          expiry != null
                              ? 'Son geçerlilik: ${expiry!.day}/${expiry!.month}/${expiry!.year}'
                              : 'Geçerlilik tarihi seç (opsiyonel)',
                          style: TextStyle(
                            color: expiry != null
                                ? const Color(0xFFE5E7EB)
                                : const Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                        if (expiry != null) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setLocal(() => expiry = null),
                            child: const Icon(Icons.close,
                                size: 16, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cancel, style: const TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, (
                title: titleCtrl.text.trim().isEmpty ? defaultName : titleCtrl.text.trim(),
                category: category,
                expiry: expiry,
              )),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFromPicker() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
    );
    if (file == null) return;
    await _collectMetadataAndUpload(File(file.path), file.name);
  }

  Future<void> _uploadFromCamera() async {
    final granted = await PermissionService.requestCamera(context);
    if (!granted) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
    );
    if (file == null) return;
    await _collectMetadataAndUpload(File(file.path), file.name);
  }

  Future<void> _collectMetadataAndUpload(File file, String defaultName) async {
    if (!mounted) return;
    final meta = await _showMetadataDialog(defaultName);
    if (meta == null) return; // user cancelled
    await _uploadFile(file, meta.title, meta.category, meta.expiry);
  }

  Future<void> _uploadFile(
    File file,
    String fileName,
    DocumentCategory category,
    DateTime? expiryDate,
  ) async {
    setState(() => _isUploading = true);
    try {
      final familyId = await _getFamilyId();
      final isLocal = familyId == DocumentRepository.localFamilyId;

      String? ocrText;
      final ext = file.path.toLowerCase();
      if (ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.png')) {
        ocrText = await _runOcr(file.path);
      }

      String fileType = 'other';
      if (ext.endsWith('.pdf')) {
        fileType = 'pdf';
      } else if (ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.png')) {
        fileType = 'image';
      } else if (ext.endsWith('.doc') || ext.endsWith('.docx')) {
        fileType = 'doc';
      }

      if (isLocal) {
        await DocumentRepository().addLocalDocument(
          file: file,
          title: fileName,
          fileType: fileType,
          category: category,
          expiryDate: expiryDate,
        );
        if (mounted) {
          setState(() =>
              _documents = DocumentRepository().getLocalDocuments());
        }
      } else {
        await DocumentRepository().uploadDocument(
          familyId: familyId!,
          file: file,
          title: fileName,
          fileType: fileType,
          ocrText: ocrText,
          extractedData: ocrText != null ? {'raw_text': ocrText} : null,
          category: category,
          expiryDate: expiryDate,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ocrText != null && ocrText.isNotEmpty
                  ? AppLocalizations.of(context).belgeYuklendiVeOcrTamamlandi
                  : 'Belge yüklendi.',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yükleme hatası: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(FamilyDocument doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text('${doc.title} silinecek. Emin misiniz?'),
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
      if (doc.id.startsWith('local_')) {
        await DocumentRepository().deleteLocalDocument(doc.id);
        if (mounted) {
          setState(() =>
              _documents = DocumentRepository().getLocalDocuments());
        }
      } else {
        await DocumentRepository().deleteDocument(doc.id, doc.fileUrl);
      }
      HapticFeedback.mediumImpact();
    }
  }

  void _createTaskFromDocument(FamilyDocument doc) {
    final taskTitle = doc.title;
    context.push(AppRoutes.tasks, extra: {'preFillTitle': 'Belge: $taskTitle'});
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
                title: Text(AppLocalizations.of(context).belgeFotografiCek),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF6366F1),
                ),
                title: Text(AppLocalizations.of(context).galeridenBelgeSec),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromPicker();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _fileIcon(String type) {
    return switch (type) {
      'pdf' => Icons.picture_as_pdf,
      'image' => Icons.image,
      'doc' => Icons.description,
      _ => Icons.insert_drive_file,
    };
  }

  List<FamilyDocument> get _filteredDocuments =>
      _filterCategory == null
          ? _documents
          : _documents.where((d) => d.category == _filterCategory).toList();

  Color _expiryColor(FamilyDocument doc) {
    if (doc.isExpired) return const Color(0xFFEF4444);
    if (doc.isExpiringSoon) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDocuments;
    final expiringSoonCount = _documents.where((d) => d.isExpiringSoon || d.isExpired).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('Evrak Kasası'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        actions: [
          if (expiringSoonCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  '$expiringSoonCount uyarı',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: const Color(0xFFF59E0B),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _filterChip(null, 'Tümü'),
                ...DocumentCategory.values.map((c) => _filterChip(c, c.label)),
              ],
            ),
          ),
          // Document list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open,
                            size: 64, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 16),
                        Text(
                          _filterCategory == null
                              ? 'Henüz belge yok'
                              : '${_filterCategory!.label} belgesi yok',
                          style: const TextStyle(
                              fontSize: 18, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context).yuklemekIcinButonunaBasin,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return _buildDocumentCard(doc);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isUploading
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: Color(0xFF6366F1),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          : FloatingActionButton(
              onPressed: _showUploadOptions,
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _filterChip(DocumentCategory? cat, String label) {
    final selected = _filterCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _filterCategory = cat),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1) : const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : const Color(0x1EFFFFFF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : const Color(0xFF9CA3AF),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(FamilyDocument doc) {
    final hasExpiry = doc.expiryDate != null;
    final days = doc.daysUntilExpiry;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: doc.isExpired
              ? const Color(0xFFEF4444).withAlpha(80)
              : doc.isExpiringSoon
                  ? const Color(0xFFF59E0B).withAlpha(80)
                  : const Color(0x1EFFFFFF),
          width: (doc.isExpired || doc.isExpiringSoon) ? 1 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_fileIcon(doc.fileType), color: const Color(0xFF6366F1)),
                ),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFFE5E7EB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Category chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              doc.category.label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Popup menu
                PopupMenuButton<String>(
                  color: const Color(0xFF13131A),
                  onSelected: (value) {
                    if (value == 'task') _createTaskFromDocument(doc);
                    if (value == 'delete') _deleteDocument(doc);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'task',
                      child: Text(AppLocalizations.of(context).gorevOlustur,
                          style: const TextStyle(color: Color(0xFFE5E7EB))),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ),
                  ],
                ),
              ],
            ),
            // Expiry badge
            if (hasExpiry) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _expiryColor(doc).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _expiryColor(doc).withAlpha(60), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      doc.isExpired ? Icons.error_outline : Icons.access_time,
                      size: 14,
                      color: _expiryColor(doc),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      doc.isExpired
                          ? 'Süresi doldu (${days!.abs()} gün önce)'
                          : days! <= 7
                              ? 'Son $days gün!'
                              : 'Son geçerlilik: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _expiryColor(doc),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // OCR text preview
            if (doc.ocrText != null && doc.ocrText!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.text_snippet_outlined,
                        size: 14, color: Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        doc.ocrText!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
