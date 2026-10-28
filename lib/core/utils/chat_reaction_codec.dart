import '../../domain/entities.dart';

List<MessageReaction> parseMessageReactions(Object? value) {
  if (value is! Map) return const [];

  final reactions = <MessageReaction>[];
  for (final entry in value.entries) {
    final userIds = entry.value is List
        ? (entry.value as List)
            .map((id) => id.toString())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
        : <String>[];
    if (entry.key.toString().isNotEmpty && userIds.isNotEmpty) {
      reactions.add(
        MessageReaction(emoji: entry.key.toString(), userIds: userIds),
      );
    }
  }
  return reactions;
}
