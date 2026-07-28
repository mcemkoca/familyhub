import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../domain/models/health_record.dart';
import '../../../domain/models/child_account.dart';
import '../../../repositories/health_record_repository.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../../presentation/providers/child_context_provider.dart';
import '../../../presentation/widgets/settings/screen_header.dart';
import '../../../services/auth_service.dart';

/// Sağlık Kayıtları — aile üyesi bazlı gerçek CRUD (spec §16).
/// Üye + tip filtresi, liste (loading/empty/error), ekleme formu.
/// Backend'e bağlı; sahte başarı yok — kayıt gerçekten oluşmazsa hata gösterir.
class HealthRecordsScreen extends ConsumerStatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  ConsumerState<HealthRecordsScreen> createState() =>
      _HealthRecordsScreenState();
}

/// Kayıt tipi anahtarı → yerelleşmiş etiket (stabil key + 4 dil).
String recordTypeLabel(String key, String lang) {
  const m = {
    'exam': {'tr': 'Muayene', 'en': 'Exam', 'fr': 'Examen', 'nl': 'Onderzoek'},
    'hospital': {'tr': 'Hastane', 'en': 'Hospital', 'fr': 'Hôpital', 'nl': 'Ziekenhuis'},
    'emergency': {'tr': 'Acil', 'en': 'Emergency', 'fr': 'Urgence', 'nl': 'Spoed'},
    'vaccine': {'tr': 'Aşı', 'en': 'Vaccine', 'fr': 'Vaccin', 'nl': 'Vaccin'},
    'lab': {'tr': 'Lab sonucu', 'en': 'Lab result', 'fr': 'Résultat labo', 'nl': 'Labuitslag'},
    'prescription': {'tr': 'Reçete', 'en': 'Prescription', 'fr': 'Ordonnance', 'nl': 'Voorschrift'},
    'medication': {'tr': 'İlaç', 'en': 'Medication', 'fr': 'Médicament', 'nl': 'Medicatie'},
    'allergy': {'tr': 'Alerji', 'en': 'Allergy', 'fr': 'Allergie', 'nl': 'Allergie'},
    'diagnosis': {'tr': 'Tanı', 'en': 'Diagnosis', 'fr': 'Diagnostic', 'nl': 'Diagnose'},
    'surgery': {'tr': 'Operasyon', 'en': 'Surgery', 'fr': 'Opération', 'nl': 'Operatie'},
    'dental': {'tr': 'Diş', 'en': 'Dental', 'fr': 'Dentaire', 'nl': 'Tandzorg'},
    'vision': {'tr': 'Göz', 'en': 'Vision', 'fr': 'Vue', 'nl': 'Zicht'},
    'growth': {'tr': 'Büyüme', 'en': 'Growth', 'fr': 'Croissance', 'nl': 'Groei'},
    'bloodpressure': {'tr': 'Tansiyon', 'en': 'Blood pressure', 'fr': 'Tension', 'nl': 'Bloeddruk'},
    'symptom': {'tr': 'Semptom', 'en': 'Symptom', 'fr': 'Symptôme', 'nl': 'Symptoom'},
    'note': {'tr': 'Not', 'en': 'Note', 'fr': 'Note', 'nl': 'Notitie'},
    'document': {'tr': 'Belge', 'en': 'Document', 'fr': 'Document', 'nl': 'Document'},
    'other': {'tr': 'Diğer', 'en': 'Other', 'fr': 'Autre', 'nl': 'Andere'},
  };
  final e = m[key];
  return e?[lang] ?? e?['en'] ?? key;
}

const _typeKeys = [
  'exam', 'vaccine', 'lab', 'prescription', 'medication', 'allergy',
  'diagnosis', 'surgery', 'dental', 'vision', 'symptom', 'note', 'other',
];

class _HealthRecordsScreenState extends ConsumerState<HealthRecordsScreen> {
  final _repo = HealthRecordRepository.instance;
  String? _familyId;
  String? _memberFilter; // null → tümü
  String? _typeFilter; // null → tümü
  bool _loading = true;
  bool _error = false;
  List<HealthRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      _familyId ??= await ref.read(familyIdProvider.future);
      final fid = _familyId;
      if (fid == null || fid.isEmpty) {
        setState(() {
          _records = const [];
          _loading = false;
        });
        return;
      }
      final list = await _repo.listForFamily(fid,
          memberId: _memberFilter, recordType: _typeFilter);
      if (!mounted) return;
      setState(() {
        _records = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final children = ref.watch(familyChildrenProvider).asData?.value ?? const <ChildAccount>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: t.hrTitle,
        showBack: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: _familyId == null ? null : () => _openAddForm(t, lang),
        icon: const Icon(Icons.add),
        label: Text(t.hrAdd),
      ),
      body: Column(
        children: [
          // Üye filtresi
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _chip(t.hrAll, _memberFilter == null, () {
                  setState(() => _memberFilter = null);
                  _load();
                }),
                for (final c in children) ...[
                  const SizedBox(width: 8),
                  _chip(c.name, _memberFilter == c.id, () {
                    setState(() => _memberFilter = c.id);
                    _load();
                  }),
                ],
              ],
            ),
          ),
          // Tip filtresi
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(t.hrAll, _typeFilter == null, () {
                  setState(() => _typeFilter = null);
                  _load();
                }, small: true),
                for (final k in _typeKeys) ...[
                  const SizedBox(width: 6),
                  _chip(recordTypeLabel(k, lang), _typeFilter == k, () {
                    setState(() => _typeFilter = k);
                    _load();
                  }, small: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _body(t, lang)),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations t, String lang) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return _state(Icons.error_outline_rounded, t.hrError, retry: _load);
    }
    if (_records.isEmpty) {
      return _state(Icons.folder_open_outlined, t.hrEmpty);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
        itemCount: _records.length,
        itemBuilder: (_, i) => _recordCard(t, lang, _records[i]),
      ),
    );
  }

  Widget _recordCard(AppLocalizations t, String lang, HealthRecord r) {
    final dateStr = DateFormat.yMMMd(lang).format(r.recordDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _badge(recordTypeLabel(r.recordType, lang)),
            const Spacer(),
            Text(dateStr,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _confirmDelete(t, r),
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFF6B7280)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(r.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          if (r.description != null && r.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.description!,
                style: const TextStyle(
                    color: Color(0xFFD1D5DB), fontSize: 13, height: 1.4)),
          ],
          if ((r.doctor ?? '').isNotEmpty || (r.institution ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
                [r.doctor, r.institution]
                    .where((s) => (s ?? '').isNotEmpty)
                    .join(' · '),
                style:
                    const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AppLocalizations t, HealthRecord r) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        title: Text(t.hrDeleteTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(r.title,
            style: const TextStyle(color: Color(0xFFD1D5DB))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.delete,
                  style: const TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (ok != true) return;
    final done = await _repo.softDelete(r.id);
    messenger.showSnackBar(SnackBar(
        content: Text(done ? t.hrDeleted : t.hrSaveFailed),
        behavior: SnackBarBehavior.floating));
    if (done) _load();
  }

  Future<void> _openAddForm(AppLocalizations t, String lang) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddRecordSheet(
        familyId: _familyId!,
        children: ref.read(familyChildrenProvider).asData?.value ?? const <ChildAccount>[],
        lang: lang,
      ),
    );
    if (saved == true) _load();
  }

  Widget _chip(String label, bool sel, VoidCallback onTap,
      {bool small = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF3B82F6) : const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: sel ? const Color(0xFF3B82F6) : const Color(0x22FFFFFF)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: small ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : const Color(0xFF9CA3AF))),
      ),
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x223B82F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF93B4FF),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );

  Widget _state(IconData icon, String label, {VoidCallback? retry}) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: const Color(0xFF6B7280)),
            const SizedBox(height: 12),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9CA3AF))),
            if (retry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: retry,
                  child: Text(AppLocalizations.of(context).retry)),
            ],
          ],
        ),
      );
}

/// Kayıt ekleme formu (bottom sheet) — gerçek insert; başarısızsa hata.
class _AddRecordSheet extends ConsumerStatefulWidget {
  final String familyId;
  final List<ChildAccount> children;
  final String lang;
  const _AddRecordSheet(
      {required this.familyId, required this.children, required this.lang});

  @override
  ConsumerState<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<_AddRecordSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _doctor = TextEditingController();
  final _institution = TextEditingController();
  String _type = 'exam';
  String? _memberId; // null → yetişkin (kendisi)
  DateTime _date = DateTime(2026, 1, 1);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _doctor.dispose();
    _institution.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.hrNewRecord,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _field(_title, t.hrRecTitle),
            const SizedBox(height: 10),
            // Tip seçici
            Text(t.hrType,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in _typeKeys)
                  GestureDetector(
                    onTap: () => setState(() => _type = k),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _type == k
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF1B1B24),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(recordTypeLabel(k, widget.lang),
                          style: TextStyle(
                              fontSize: 12,
                              color: _type == k
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Üye seçici
            if (widget.children.isNotEmpty) ...[
              Text(t.hrMember,
                  style:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _memberChip(t.hrSelf, _memberId == null,
                    () => setState(() => _memberId = null)),
                for (final c in widget.children)
                  _memberChip(c.name, _memberId == c.id,
                      () => setState(() => _memberId = c.id)),
              ]),
              const SizedBox(height: 10),
            ],
            // Tarih
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 10),
                  Text(DateFormat.yMMMd(widget.lang).format(_date),
                      style: const TextStyle(color: Colors.white)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            _field(_doctor, t.hrDoctor),
            const SizedBox(height: 10),
            _field(_institution, t.hrInstitution),
            const SizedBox(height: 10),
            _field(_desc, t.hrDesc, maxLines: 3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _saving || _title.text.trim().isEmpty ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(t.hrSave,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final memberType = _memberId == null ? 'adult' : 'child';
    final memberId = _memberId ?? (AuthService.currentUserId ?? 'self');
    final record = HealthRecord(
      id: '',
      familyId: widget.familyId,
      memberId: memberId,
      memberType: memberType,
      recordType: _type,
      title: _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      doctor: _doctor.text.trim().isEmpty ? null : _doctor.text.trim(),
      institution:
          _institution.text.trim().isEmpty ? null : _institution.text.trim(),
      recordDate: _date,
    );
    final created = await _repoCreate(record);
    if (!mounted) return;
    setState(() => _saving = false);
    if (created != null) {
      navigator.pop(true);
    } else {
      // Sahte başarı YOK — gerçek hata göster.
      messenger.showSnackBar(SnackBar(
          content: Text(t.hrSaveFailed),
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<HealthRecord?> _repoCreate(HealthRecord r) =>
      HealthRecordRepository.instance.create(r);

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
          filled: true,
          fillColor: const Color(0xFF1B1B24),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      );

  Widget _memberChip(String label, bool sel, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF10B981) : const Color(0xFF1B1B24),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: sel ? Colors.white : const Color(0xFF9CA3AF))),
        ),
      );
}
