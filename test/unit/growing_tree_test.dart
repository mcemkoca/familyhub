import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/presentation/widgets/growing_tree.dart';

void main() {
  group('GrowingTree.stageLabelFor', () {
    test('eşik değerlerinde doğru aşama', () {
      expect(GrowingTree.stageLabelFor(0.0), contains('Tohum'));
      expect(GrowingTree.stageLabelFor(0.19), contains('Tohum'));
      expect(GrowingTree.stageLabelFor(0.2), contains('Filiz'));
      expect(GrowingTree.stageLabelFor(0.45), contains('Yaprak'));
      expect(GrowingTree.stageLabelFor(0.7), contains('Çiçek'));
      expect(GrowingTree.stageLabelFor(0.95), contains('Meyve'));
      expect(GrowingTree.stageLabelFor(1.0), contains('Meyve'));
    });

    test('aralık dışı değerler kırpılır', () {
      expect(GrowingTree.stageLabelFor(-0.5), contains('Tohum'));
      expect(GrowingTree.stageLabelFor(2.0), contains('Meyve'));
    });

    test('aşamalar ilerledikçe monoton değişir', () {
      final labels = [0.1, 0.3, 0.5, 0.8, 0.99]
          .map(GrowingTree.stageLabelFor)
          .toList();
      // Her aşama bir öncekinden farklı olmalı (5 ayrı aşama)
      expect(labels.toSet().length, 5);
    });
  });
}
