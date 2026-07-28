import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../repositories/gallery_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/gallery_sync_service.dart';
import '../../../services/permission_service.dart';
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
    _maybeAutoSync();
  }

  // Otomatik senkron açıksa, açılışta yeni cihaz fotoğraflarını sessizce yükle.
  Future<void> _maybeAutoSync() async {
    if (!GallerySyncService.autoSyncEnabled) return;
    try {
      final n = await GallerySyncService.syncRecentPhotos();
      if (n > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$n yeni fotoğraf otomatik senkronlandı')),
        );
      }
    } catch (e) {
      debugPrint('Otomatik senkron atlandı: $e');
    }
  }

  // Kullanıcı manuel senkron tetikler + otomatik senkron ayarını değiştirir.
  Future<void> _manualSync() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadTotal = 0;
    });
    try {
      final n = await GallerySyncService.syncRecentPhotos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(n > 0
              ? '$n yeni fotoğraf senkronlandı'
              : 'Yeni fotoğraf yok — her şey güncel')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).galSyncFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return GalleryRepository.localFamilyId;
    try {
      final profile = await AuthService.safeClient
          ?.from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      return (profile?['family_id'] as String?) ??
          GalleryRepository.localFamilyId;
    } catch (_) {
      return GalleryRepository.localFamilyId;
    }
  }

  void _subscribe() async {
    final familyId = await _getFamilyId();
    // Yerel mod — Hive'daki yerel medyayı yükle (realtime yok).
    if (familyId == GalleryRepository.localFamilyId) {
      if (mounted) {
        setState(() => _media = GalleryRepository().getLocalMedia());
      }
      return;
    }
    _sub?.cancel();
    _sub = GalleryRepository().watchMedia(familyId!).listen(
          (media) => setState(() => _media = media),
          onError: (e) => debugPrint('Gallery stream error: $e'),
        );
  }

  // ── MULTI PICK FROM PHONE GALLERY ──
  Future<void> _pickMultipleFromGallery() async {
    final granted = await PermissionService.requestPhotos(context);
    if (!granted) return;

    final files = await _picker.pickMultipleMedia(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (files.isEmpty) return;

    await _uploadBatch(files);
  }

  Future<void> _pickFromCamera() async {
    final granted = await PermissionService.requestCamera(context);
    if (!granted) return;

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
    final isLocal = familyId == GalleryRepository.localFamilyId;

    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final ext = f.path.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
      try {
        if (isLocal) {
          await GalleryRepository().addLocalMedia(
              File(f.path), isVideo ? 'video' : 'image');
        } else {
          await GalleryRepository().uploadMedia(
            familyId: familyId!,
            file: File(f.path),
            type: isVideo ? 'video' : 'image',
          );
        }
      } catch (e) {
        debugPrint('Upload error for ${f.name}: $e');
      }
      if (mounted) setState(() => _uploadProgress = i + 1);
    }

    // Yerel modda realtime yok — listeyi Hive'dan yeniden yükle.
    if (isLocal && mounted) {
      setState(() => _media = GalleryRepository().getLocalMedia());
    }
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${files.length} fotoğraf/video yüklendi')),
      );
    }
  }

  Future<void> _deleteMedia(FamilyMedia media) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).delete),
        content: Text(AppLocalizations.of(context).galDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).budDelete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (media.id.startsWith('local_')) {
        await GalleryRepository().deleteLocalMedia(media.id);
        if (mounted) {
          setState(() => _media = GalleryRepository().getLocalMedia());
        }
      } else {
        await GalleryRepository().deleteMedia(media.id, media.url);
      }
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
              child: galleryImage(media.url, fit: BoxFit.contain),
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
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withAlpha(18), width: 0.5),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _DarkListTile(
                  icon: Icons.photo_library_outlined,
                  color: const Color(0xFFEC4899),
                  title: AppLocalizations.of(context).galPickMulti,
                  subtitle: AppLocalizations.of(context).birdenFazlaFotografVeyaVideo,
                  onTap: () { Navigator.pop(context); _pickMultipleFromGallery(); },
                ),
                const SizedBox(height: 8),
                _DarkListTile(
                  icon: Icons.camera_alt_outlined,
                  color: const Color(0xFF6366F1),
                  title: AppLocalizations.of(context).fotografCek,
                  onTap: () { Navigator.pop(context); _pickFromCamera(); },
                ),
                const SizedBox(height: 8),
                _DarkListTile(
                  icon: Icons.sync,
                  color: const Color(0xFF10B981),
                  title: AppLocalizations.of(context).galSyncDevice,
                  subtitle: AppLocalizations.of(context).galSyncDeviceSub,
                  onTap: () { Navigator.pop(context); _manualSync(); },
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setSheet) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withAlpha(18), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.autorenew, size: 18, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(AppLocalizations.of(context).galAutoSync,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE5E7EB))),
                        ),
                        Switch(
                          value: GallerySyncService.autoSyncEnabled,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (v) async {
                            await GallerySyncService.setAutoSync(v);
                            setSheet(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
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
        title: AppLocalizations.of(context).bugununAnilari,
        subtitle: '${today.length} fotoğraf/video',
        icon: Icons.today,
        color: const Color(0xFF6366F1),
        media: today,
      ));
    }

    // 2. 1 Yıl Önce Bugün
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final yearAgo = _media.where((m) => _isSameDay(m.createdAt, oneYearAgo)).toList();
    if (yearAgo.isNotEmpty) {
      memories.add(_MemoryGroup(
        title: AppLocalizations.of(context).yilOnceBugun,
        subtitle: DateFormat('dd MMMM yyyy', 'tr_TR').format(oneYearAgo),
        icon: Icons.history,
        color: const Color(0xFF8B5CF6),
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
        title: AppLocalizations.of(context).gecenHaftaSonu,
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
        title: AppLocalizations.of(context).son30Gun,
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
        title: AppLocalizations.of(context).videolarimiz,
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
        title: AppLocalizations.of(context).ilkAnilar,
        subtitle: DateFormat('MMMM yyyy', 'tr_TR').format(oldest.first.createdAt),
        icon: Icons.auto_awesome,
        color: const Color(0xFFEC4899),
        media: oldest,
      ));
    }

    return memories;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFEC4899);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF6B7280)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [BoxShadow(color: pink.withAlpha(80), blurRadius: 10)],
              ),
              child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).galTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFE5E7EB))),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: pink,
          labelColor: pink,
          unselectedLabelColor: const Color(0xFF6B7280),
          dividerColor: Colors.white.withAlpha(12),
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.grid_on_outlined, size: 16), text: 'Galeri'),
            Tab(icon: Icon(Icons.auto_awesome_outlined, size: 16), text: 'Anılar'),
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
              backgroundColor: const Color(0xFF6366F1),
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
              backgroundColor: const Color(0xFF6366F1),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(AppLocalizations.of(context).crashAdd, style: const TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _buildGalleryTab() {
    if (_media.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library, size: 64, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).henuzFotografYok, style: const TextStyle(fontSize: 18, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).telefonGalerisindenSecmekIcinButonunaBasin, style: const TextStyle(color: Color(0xFF6B7280))),
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
                galleryImage(m.thumbnailUrl ?? m.url, fit: BoxFit.cover),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 64, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).henuzAniOlusmadi, style: const TextStyle(fontSize: 18, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).dahaFazlaFotografEkledikceAnilarOlusacak, style: const TextStyle(color: Color(0xFF6B7280))),
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
                  galleryImage(
                      mem.media.first.thumbnailUrl ?? mem.media.first.url,
                      fit: BoxFit.cover),
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
                                    image: galleryImageProvider(m.thumbnailUrl ?? m.url),
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
                  galleryImage(m.thumbnailUrl ?? m.url, fit: BoxFit.cover),
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
              child: galleryImage(media.url, fit: BoxFit.contain),
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

class _DarkListTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _DarkListTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(18), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE5E7EB))),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF4B5563)),
          ],
        ),
      ),
    );
  }
}


// ── Galeri medya görüntüleyici: yerel dosya yolu mu network URL mü ayırır ──
Widget galleryImage(String url, {BoxFit fit = BoxFit.cover}) {
  if (url.startsWith('http')) {
    return Image.network(url,
        fit: fit,
        loadingBuilder: (_, child, p) =>
            p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white30));
  }
  return Image.file(File(url),
      fit: fit,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white30));
}

ImageProvider galleryImageProvider(String url) =>
    url.startsWith('http') ? NetworkImage(url) : FileImage(File(url)) as ImageProvider;
