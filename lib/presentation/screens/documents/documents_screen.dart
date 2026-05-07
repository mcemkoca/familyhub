import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// file_picker removed — using image_picker only
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../repositories/document_repository.dart';
import '../../../services/auth_service.dart';
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
    _sub = DocumentRepository()
        .watchDocuments(familyId)
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

  Future<void> _uploadFromPicker() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
    );
    if (file == null) return;
    await _uploadFile(File(file.path), file.name);
  }

  Future<void> _uploadFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kamera izni gerekli')));
      }
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
    );
    if (file == null) return;
    await _uploadFile(File(file.path), file.name);
  }

  Future<void> _uploadFile(File file, String fileName) async {
    setState(() => _isUploading = true);
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) return;

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

      await DocumentRepository().uploadDocument(
        familyId: familyId,
        file: file,
        title: fileName,
        fileType: fileType,
        ocrText: ocrText,
        extractedData: ocrText != null ? {'raw_text': ocrText} : null,
      );

      if (mounted && ocrText != null && ocrText.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).belgeYuklendiVeOcrTamamlandi)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yükleme hatası: $e')));
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
      await DocumentRepository().deleteDocument(doc.id, doc.fileUrl);
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
                leading: const Icon(Icons.camera_alt, color: AppColors.cobalt),
                title: Text(AppLocalizations.of(context).belgeFotografiCek),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.cobalt,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Aile Belgeleri'), centerTitle: true),
      body: _documents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: AppColors.lightGray),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz belge yok',
                    style: TextStyle(fontSize: 18, color: AppColors.gray),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yüklemek için + butonuna basın',
                    style: TextStyle(color: AppColors.slate),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.cobalt.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _fileIcon(doc.fileType),
                                color: AppColors.cobalt,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'task') {
                                  _createTaskFromDocument(doc);
                                }
                                if (value == 'delete') {
                                  _deleteDocument(doc);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'task',
                                  child: Text(AppLocalizations.of(context).gorevOlustur),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Sil',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (doc.ocrText != null && doc.ocrText!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.cloudWhite,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.text_snippet,
                                      size: 16,
                                      color: AppColors.cobalt,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'OCR Sonucu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.cobalt,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doc.ocrText!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.gray,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _isUploading
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: AppColors.cobalt,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          : FloatingActionButton(
              onPressed: _showUploadOptions,
              backgroundColor: AppColors.cobalt,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}
