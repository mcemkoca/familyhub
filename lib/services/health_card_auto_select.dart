import '../domain/models/family_member_model.dart';

class EmergencyContactAutoSelect {
  /// Öncelik sırası: Eş > Anne > Baba > Çocuk > Kardeş > Dost
  static final List<String> _priorityOrder = [
    'eş',
    'anne',
    'baba',
    'çocuk',
    'kardeş',
    'dost',
  ];

  static EmergencyContactResult autoSelect(List<FamilyMemberModel> members) {
    for (final relation in _priorityOrder) {
      final match = members.firstWhere(
        (m) => m.relation?.toLowerCase() == relation,
        orElse: () => FamilyMemberModel(
          id: '',
          name: '',
          role: '',
          memberType: '',
          relation: '',
        ),
      );
      if (match.id.isNotEmpty) {
        return EmergencyContactResult(
          name: match.name,
          relation: match.relation ?? relation,
          phone: match.phone ?? '',
          isAutoSelected: true,
        );
      }
    }

    // Hiçbiri yoksa boş döndür
    return EmergencyContactResult.empty();
  }
}

class EmergencyContactResult {
  final String name;
  final String relation;
  final String phone;
  final bool isAutoSelected;

  EmergencyContactResult({
    required this.name,
    required this.relation,
    required this.phone,
    required this.isAutoSelected,
  });

  EmergencyContactResult.empty()
      : name = '',
        relation = '',
        phone = '',
        isAutoSelected = false;

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'phone': phone,
        'isAutoSelected': isAutoSelected,
      };
}
