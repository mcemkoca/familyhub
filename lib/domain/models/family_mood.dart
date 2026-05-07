/// Mood entry shared by a family member.
class FamilyMood {
  final String id;
  final String emoji;
  final String? note;
  final int? energyLevel;

  FamilyMood({
    required this.id,
    required this.emoji,
    this.note,
    this.energyLevel,
  });

  factory FamilyMood.fromJson(Map<String, dynamic> json) => FamilyMood(
        id: json['id'] as String? ?? '',
        emoji: json['mood_emoji'] as String? ?? '😊',
        note: json['mood_note'] as String?,
        energyLevel: json['energy_level'] as int?,
      );
}
