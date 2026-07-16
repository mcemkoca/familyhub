import '../domain/models/family_member_model.dart';

class EmergencyContactAutoSelect {
  /// Priority: spouse > mother > father > child > sibling > friend.
  static const List<Set<String>> _priorityOrder = [
    {'eş', 'es', 'spouse', 'partner', 'echtgenoot', 'echtgenote', 'conjoint', 'conjointe'},
    {'anne', 'mother', 'mom', 'mum', 'moeder', 'mère'},
    {'baba', 'father', 'dad', 'vader', 'père'},
    {'çocuk', 'cocuk', 'child', 'kind', 'enfant'},
    {'kardeş', 'kardes', 'sibling', 'brother', 'sister', 'broer', 'zus', 'frère', 'sœur'},
    {'dost', 'arkadaş', 'arkadas', 'friend', 'vriend', 'vriendin', 'ami', 'amie'},
  ];

  static EmergencyContactResult autoSelect(List<FamilyMemberModel> members) {
    for (final aliases in _priorityOrder) {
      final match = members.firstWhere(
        (m) => aliases.contains(m.relation?.trim().toLowerCase()),
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
          relation: match.relation ?? aliases.first,
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
