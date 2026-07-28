/// Sağlık kaydı domain modeli (aile üyesi bazlı).
/// record_type ve privacy_level STABLE KEY olarak saklanır (UI'da yerelleşir).
library;

class HealthRecord {
  final String id;
  final String familyId;
  final String memberId;
  final String memberType; // adult | child | other
  final String recordType; // exam | vaccine | lab | prescription | ...
  final String title;
  final String? description;
  final String? doctor;
  final String? institution;
  final String? address;
  final DateTime recordDate;
  final String privacyLevel; // private | family | caregivers
  final String? attachmentUrl;
  final List<String> tags;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HealthRecord({
    required this.id,
    required this.familyId,
    required this.memberId,
    required this.memberType,
    required this.recordType,
    required this.title,
    this.description,
    this.doctor,
    this.institution,
    this.address,
    required this.recordDate,
    this.privacyLevel = 'family',
    this.attachmentUrl,
    this.tags = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime _date(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static DateTime? _dateN(dynamic v) =>
      (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;

  factory HealthRecord.fromJson(Map<String, dynamic> j) => HealthRecord(
        id: (j['id'] ?? '').toString(),
        familyId: (j['family_id'] ?? '').toString(),
        memberId: (j['member_id'] ?? '').toString(),
        memberType: (j['member_type'] ?? 'adult').toString(),
        recordType: (j['record_type'] ?? 'note').toString(),
        title: (j['title'] ?? '').toString(),
        description: j['description'] as String?,
        doctor: j['doctor'] as String?,
        institution: j['institution'] as String?,
        address: j['address'] as String?,
        recordDate: _date(j['record_date']),
        privacyLevel: (j['privacy_level'] ?? 'family').toString(),
        attachmentUrl: j['attachment_url'] as String?,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        createdBy: j['created_by'] as String?,
        createdAt: _dateN(j['created_at']),
        updatedAt: _dateN(j['updated_at']),
      );

  /// Insert/update için map (id/timestamps backend'de üretilir).
  Map<String, dynamic> toInsert() => {
        'family_id': familyId,
        'member_id': memberId,
        'member_type': memberType,
        'record_type': recordType,
        'title': title,
        if (description != null) 'description': description,
        if (doctor != null) 'doctor': doctor,
        if (institution != null) 'institution': institution,
        if (address != null) 'address': address,
        'record_date': recordDate.toIso8601String().split('T').first,
        'privacy_level': privacyLevel,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        'tags': tags,
      };
}
