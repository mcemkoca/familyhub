import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/repositories/chat_repository.dart';

/// FAZ 1 — read-receipt gösterim hesabı (computeReadCount).
void main() {
  final msgTime = DateTime.utc(2026, 1, 1, 12, 0, 0);
  Map<String, dynamic> rs(String uid, DateTime at) =>
      {'user_id': uid, 'last_read_at': at.toIso8601String()};

  int count(List<Map<String, dynamic>> states,
          {String sender = 'sender', String me = 'me'}) =>
      computeReadCount(
        messageSenderId: sender,
        messageCreatedAt: msgTime,
        readStates: states,
        myId: me,
      );

  test('kimse okumadıysa 0 (sent)', () {
    expect(count(const []), 0);
  });

  test('karşı üye mesajdan sonra okuduysa 1 (read)', () {
    expect(count([rs('other', msgTime.add(const Duration(minutes: 5)))]), 1);
  });

  test('karşı üye mesajdan ÖNCE okuduysa sayılmaz', () {
    expect(count([rs('other', msgTime.subtract(const Duration(minutes: 5)))]), 0);
  });

  test('tam eşit zaman okundu sayılır (>=)', () {
    expect(count([rs('other', msgTime)]), 1);
  });

  test('kendi (myId) okuması sayılmaz', () {
    expect(count([rs('me', msgTime.add(const Duration(minutes: 5)))]), 0);
  });

  test('gönderenin kendi okuması sayılmaz', () {
    expect(count([rs('sender', msgTime.add(const Duration(minutes: 5)))]), 0);
  });

  test('grup: iki karşı üye okuduysa 2', () {
    expect(
        count([
          rs('a', msgTime.add(const Duration(minutes: 1))),
          rs('b', msgTime.add(const Duration(minutes: 2))),
        ]),
        2);
  });

  test('duplicate/bozuk kayıtlar güvenli', () {
    expect(
        count([
          {'user_id': null, 'last_read_at': msgTime.toIso8601String()},
          {'user_id': 'a', 'last_read_at': null},
          {'user_id': 'b', 'last_read_at': 'bozuk-tarih'},
        ]),
        0);
  });

  test('başka üye okuduysa ama gönderen benim → read hesaplanır', () {
    // Benim gönderdiğim mesaj (sender=me), başka üye okudu.
    expect(count([rs('other', msgTime.add(const Duration(minutes: 1)))],
            sender: 'me', me: 'me'),
        1);
  });
}
