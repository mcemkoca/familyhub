import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/domain/entities.dart';

/// FAZ 2 — anket hesap mantığı (PollData).
double pct(PollData p, int i) =>
    p.totalVotes == 0 ? 0 : p.votes[i].length / p.totalVotes * 100;

void main() {
  PollData poll({bool multiple = false}) => PollData(
        question: 'Q',
        options: const ['A', 'B', 'C'],
        votes: const [[], [], []],
        multiple: multiple,
      );

  test('sıfır oyda yüzde 0, divide-by-zero yok', () {
    final p = poll();
    expect(p.totalVotes, 0);
    expect(pct(p, 0), 0);
  });

  test('vote count doğru hesaplanır', () {
    var p = poll();
    p = p.toggleVote(0, 'u1');
    p = p.toggleVote(0, 'u2');
    p = p.toggleVote(1, 'u3');
    expect(p.votes[0].length, 2);
    expect(p.votes[1].length, 1);
    expect(p.totalVotes, 3);
    expect(pct(p, 0), closeTo(66.6, 0.1));
  });

  test('single-select: yeni oy eski oyu değiştirir (duplicate yok)', () {
    var p = poll();
    p = p.toggleVote(0, 'u1');
    p = p.toggleVote(1, 'u1'); // u1 fikrini değiştirdi
    expect(p.votes[0].contains('u1'), isFalse);
    expect(p.votes[1].contains('u1'), isTrue);
    expect(p.totalVotes, 1); // iki kez sayılmaz
  });

  test('single-select: aynı seçeneğe tekrar = oyu geri çek', () {
    var p = poll();
    p = p.toggleVote(0, 'u1');
    p = p.toggleVote(0, 'u1');
    expect(p.hasVoted('u1'), isFalse);
    expect(p.totalVotes, 0);
  });

  test('multi-select: birden fazla seçenek seçilebilir', () {
    var p = poll(multiple: true);
    p = p.toggleVote(0, 'u1');
    p = p.toggleVote(2, 'u1');
    expect(p.votes[0].contains('u1'), isTrue);
    expect(p.votes[2].contains('u1'), isTrue);
    expect(p.totalVotes, 2);
  });

  test('hasVoted current user tespiti', () {
    var p = poll();
    expect(p.hasVoted('u1'), isFalse);
    p = p.toggleVote(1, 'u1');
    expect(p.hasVoted('u1'), isTrue);
  });

  test('json round-trip oyları korur', () {
    var p = poll().toggleVote(0, 'u1').toggleVote(1, 'u2');
    final back = PollData.fromJson(p.toJson());
    expect(back.votes[0], ['u1']);
    expect(back.votes[1], ['u2']);
    expect(back.totalVotes, 2);
  });
}
