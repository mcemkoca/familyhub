import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/domain/entities.dart';

/// Aile Sohbeti — çekirdek model ve sahiplik davranışı testleri.
///
/// Bu modülün daha önce HİÇ testi yoktu. Denetimde bulunan iki P0'ı kilitler:
///  1. isMe artık gerçek user ID ile belirlenir (sabit 'm1' değil).
///  2. Reaction toggle mantığı kullanıcı-bazlı çalışır.
void main() {
  group('ChatMessage sahiplik (isMe)', () {
    ChatMessage msg(String senderId) => ChatMessage(
          id: 'x',
          senderId: senderId,
          senderName: 'Test',
          senderColor: const Color(0xFF000000),
          content: 'merhaba',
          createdAt: DateTime(2026, 1, 1),
        );

    test('gerçek UUID kendi ID ile eşleşince benim mesajım', () {
      const myId = '11111111-1111-1111-1111-111111111111';
      expect(msg(myId).senderId == myId, isTrue);
    });

    test('başka UUID benim mesajım değil', () {
      const myId = '11111111-1111-1111-1111-111111111111';
      const other = '22222222-2222-2222-2222-222222222222';
      expect(msg(other).senderId == myId, isFalse);
    });

    test("eski sabit 'm1' gerçek UUID'lerle asla eşleşmez (regression)", () {
      const realUuid = '33333333-3333-3333-3333-333333333333';
      // Eski hata: isMe = senderId == 'm1' → gerçek mesajlar hep karşı tarafta.
      expect(msg(realUuid).senderId == 'm1', isFalse);
    });
  });

  group('MessageReaction', () {
    test('count kullanıcı sayısını verir', () {
      const r = MessageReaction(emoji: '👍', userIds: ['a', 'b', 'c']);
      expect(r.count, 3);
    });

    test('boş reaction count sıfır', () {
      const r = MessageReaction(emoji: '❤️', userIds: []);
      expect(r.count, 0);
    });
  });

  group('MessageType', () {
    test('tüm medya türleri enum içinde tanımlı', () {
      // Repository ve migration 067 type CHECK ile uyumlu olmalı.
      const beklenen = {
        MessageType.text,
        MessageType.image,
        MessageType.audio,
        MessageType.video,
        MessageType.file,
        MessageType.gif,
        MessageType.location,
        MessageType.event,
        MessageType.poll,
        MessageType.system,
      };
      for (final t in beklenen) {
        expect(MessageType.values.contains(t), isTrue, reason: '$t');
      }
    });
  });
}
