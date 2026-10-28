import 'package:familyhub/core/utils/chat_reaction_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMessageReactions', () {
    test('parses user ids and removes duplicates', () {
      final reactions = parseMessageReactions({
        '👍': ['user-1', 'user-2', 'user-1'],
      });

      expect(reactions, hasLength(1));
      expect(reactions.single.emoji, '👍');
      expect(reactions.single.userIds, ['user-1', 'user-2']);
    });

    test('ignores empty reactions and malformed values', () {
      expect(
        parseMessageReactions({'👍': <String>[], '❤️': 'not-a-list'}),
        isEmpty,
      );
      expect(parseMessageReactions('legacy-value'), isEmpty);
      expect(parseMessageReactions(null), isEmpty);
    });
  });
}
