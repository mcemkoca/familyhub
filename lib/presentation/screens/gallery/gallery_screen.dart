import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../repositories/gallery_repository.dart';
import '../../../services/auth_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen>
    with SingleTickerProviderStateMixin {
  List<FamilyMedia> _media = [];
  StreamSubscription<List<FamilyMedia>>? _sub;
  bool _isUploading = false;
  int _uploadProgress = 0;
  int _uploadTotal = 0;
  late TabController _tabController;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

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
    _sub = GalleryRepository().watchMedia(familyId).listen(
          (media) => setState(() => _media = media),
          onError: (e) => debugPrint('Gallery stream error: $e'),
        );
  }

  // ── MULTI PICK FROM PHONE GALLERY ──
  Future<void> _pickMultipleFromGallery() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Galeri izni gerekli')),
        );
      }
      return;
    }

    final files = await _picker.pickMultipleMedia(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (files.isEmpty) return;

    await _uploadBatch(files);
  }

  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni gerekli')),
        );
      }
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file == null) return;
    await _uploadBatch([file]);
  }

  Future<void> _uploadBatch(List<XFile> files) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadTotal = files.length;
    });

    final familyId = await _getFamilyId();
    if (familyId == null) return;

    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final ext = f.path.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
      try {
        await GalleryRepository().uploadMedia(
          familyId: familyId,
          file: File(f.path),
          type: isVideo ? 'video' : 'image',
        );
      } catch (e) {
        debugPrint('Upload error for ${f.name}: $e');
      }
      if (mounted) setState(() => _uploadProgress = i + 1);
    }

    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$files.length fotoğraf/video yüklendi')),
      );
    }
  }

  Future<void> _deleteMedia(FamilyMedia media) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).delete),
        content: const Text('Bu medya silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await GalleryRepository().deleteMedia(media.id, media.url);
      HapticFeedback.mediumImpact();
    }
  }

  void _showImageDialog(FamilyMedia media) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Image.network(media.url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (media.caption != null)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(media.caption!, style: const TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
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
                leading: const Icon(Icons.photo_library, color: AppColors.cobalt),
                title: const Text('Telefon Galerisinden Seç (Çoklu)'),
                subtitle: Text(AppLocalizations.of(context).birdenFazlaFotografVeyaVideo),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.cobalt),
                title: Text(AppLocalizations.of(context).fotografCek),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MEMORIES GENERATION ──
  List<_MemoryGroup> _buildMemories() {
    final memories = <_MemoryGroup>[];
    final now = DateTime.now();

    // 1. Bugünün Anıları
    final today = _media.where((m) => _isSameDay(m.createdAt, now)).toList();
    if (today.length >= 2) {
      memories.add(_MemoryGroup(
        title: 'Bugünün Anıları',
        subtitle: '${today.length} fotoğraf/video',
        icon: Icons.today,
        color: AppColors.cobalt,
        media: today,
      ));
    }

    // 2. 1 Yıl Önce Bugün
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final yearAgo = _media.where((m) => _isSameDay(m.createdAt, oneYearAgo)).toList();
    if (yearAgo.isNotEmpty) {
      memories.add(_MemoryGroup(
        title: '1 Yıl Önce Bugün',
        subtitle: DateFormat('dd MMMM yyyy', 'tr_TR').format(oneYearAgo),
        icon: Icons.history,
        color: AppColors.purple,
        media: yearAgo,
      ));
    }

    // 3. Geçen Hafta Sonu
    final lastSat = now.subtract(Duration(days: now.weekday + 1));
    final lastSun = now.subtract(Duration(days: now.weekday));
    final weekend = _media.where((m) {
      return m.createdAt.isAfter(lastSat.subtract(const Duration(days: 1))) &&
          m.createdAt.isBefore(lastSun.add(const Duration(days: 1)));
    }).toList();
    if (weekend.length >= 2) {
      memories.add(_MemoryGroup(
        title: 'Geçen Hafta Sonu',
        subtitle: '${DateFormat('dd MMM', 'tr_TR').format(lastSat)} - ${DateFormat('dd MMM', 'tr_TR').format(lastSun)}',
        icon: Icons.weekend,
        color: AppColors.orange,
        media: weekend,
      ));
    }

    // 4. Son 30 Gün
    final last30 = _media.where((m) => m.createdAt.isAfter(now.subtract(const Duration(days: 30)))).toList();
    if (last30.length >= 3) {
      memories.add(_MemoryGroup(
        title: 'Son 30 Gün',
        subtitle: '${last30.length} anı',
        icon: Icons.calendar_month,
        color: AppColors.green,
        media: last30,
      ));
    }

    // 5. Videolar
    final videos = _media.where((m) => m.type == 'video').toList();
    if (videos.length >= 2) {
      memories.add(_MemoryGroup(
        title: 'Videolarımız',
        subtitle: '${videos.length} video',
        icon: Icons.videocam,
        color: AppColors.error,
        media: videos,
      ));
    }

    // 6. İlk Anılar (en eski 5)
    final sortedByDate = [..._media]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final oldest = sortedByDate.take(5).toList();
    if (oldest.length >= 3) {
      memories.add(_MemoryGroup(
        title: 'İlk Anılar',
        subtitle: DateFormat('MMMM yyyy', 'tr_TR').format(oldest.first.createdAt),
        icon: Icons.auto_awesome,
        color: AppColors.pink,
        media: oldest,
      ));
    }

    return memories;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aile Galerisi'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cobalt,
          labelColor: AppColors.cobalt,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on), text: 'Galeri'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'Anılar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGalleryTab(),
          _buildMemoriesTab(),
        ],
      ),
      floatingActionButton: _isUploading
          ? FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: AppColors.cobalt,
              label: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('$_uploadProgress/$_uploadTotal', style: const TextStyle(color: Colors.white)),
                ],
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _showUploadOptions,
              backgroundColor: AppColors.cobalt,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _buildGalleryTab() {
    if (_media.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: AppColors.lightGray),
            SizedBox(height: 16),
            Text('Henüz fotoğraf yok', style: TextStyle(fontSize: 18, color: AppColors.gray)),
            SizedBox(height: 8),
            Text('Telefon galerisinden seçmek için + butonuna basın', style: TextStyle(color: AppColors.slate)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _media.length,
      itemBuilder: (context, index) {
        final m = _media[index];
        return GestureDetector(
          onTap: () => _showImageDialog(m),
          onLongPress: () => _deleteMedia(m),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  m.thumbnailUrl ?? m.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                if (m.type == 'video')
                  const Center(
                    child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('dd.MM.yy').format(m.createdAt),
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemoriesTab() {
    final memories = _buildMemories();
    if (memories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: AppColors.lightGray),
            SizedBox(height: 16),
            Text('Henüz anı oluşmadı', style: TextStyle(fontSize: 18, color: AppColors.gray)),
            SizedBox(height: 8),
            Text('Daha fazla fotoğraf ekledikçe anılar oluşacak', style: TextStyle(color: AppColors.slate)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final mem = memories[index];
        return GestureDetector(
          onTap: () => _showMemoryDetail(mem),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: mem.color.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image (first media)
                  Image.network(
                    mem.media.first.thumbnailUrl ?? mem.media.first.url,
                    fit: BoxFit.cover,
                  ),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: mem.color.withAlpha(200),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(mem.icon, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mem.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mem.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Mini thumbnails row
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: mem.media.take(4).map((m) {
                              return Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white54),
                                  image: DecorationImage(
                                    image: NetworkImage(m.thumbnailUrl ?? m.url),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMemoryDetail(_MemoryGroup memory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MemoryDetailScreen(memory: memory),
      ),
    );
  }
}

// ── MEMORY DETAIL SCREEN ──
class _MemoryDetailScreen extends StatelessWidget {
  final _MemoryGroup memory;

  const _MemoryDetailScreen({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(memory.title),
        backgroundColor: memory.color,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: memory.media.length,
        itemBuilder: (context, index) {
          final m = memory.media[index];
          return GestureDetector(
            onTap: () => _showFullScreen(context, m),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    m.thumbnailUrl ?? m.url,
                    fit: BoxFit.cover,
                  ),
                  if (m.type == 'video')
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy', 'tr_TR').format(m.createdAt),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreen(BuildContext context, FamilyMedia media) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Image.network(media.url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryGroup {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<FamilyMedia> media;

  const _MemoryGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.media,
  });
}
