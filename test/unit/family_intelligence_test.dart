import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/family_intelligence/application/family_intelligence_engine.dart';
import 'package:familyhub/features/family_intelligence/domain/family_insight.dart';

void main() {
  const engine = FamilyIntelligenceEngine();

  group('FamilyIntelligenceEngine — kural tabanlı, deterministik', () {
    test('geciken görev → high öncelikli warning', () {
      final r = engine.generate(const FamilySnapshot(overdueTasks: 3));
      final overdue = r.firstWhere((i) => i.id == 'overdue_tasks');
      expect(overdue.priority, InsightPriority.high);
      expect(overdue.type, InsightType.warning);
      expect(overdue.args['count'], '3');
      expect(overdue.actionRoute, isNotNull);
      expect(overdue.reasonKey.isNotEmpty, true); // "neden gösterildi" zorunlu
    });

    test('yaklaşan ödeme (<=3 gün) → high; uzak ödeme üretmez', () {
      expect(
          engine
              .generate(const FamilySnapshot(upcomingPaymentDays: 2))
              .any((i) => i.id == 'upcoming_payment'),
          true);
      expect(
          engine
              .generate(const FamilySnapshot(upcomingPaymentDays: 10))
              .any((i) => i.id == 'upcoming_payment'),
          false);
      expect(
          engine
              .generate(const FamilySnapshot(upcomingPaymentDays: -1))
              .any((i) => i.id == 'upcoming_payment'),
          false);
    });

    test('bekleyen alışveriş eşiği (>=3)', () {
      expect(
          engine
              .generate(const FamilySnapshot(pendingShoppingItems: 2))
              .any((i) => i.id == 'pending_shopping'),
          false);
      expect(
          engine
              .generate(const FamilySnapshot(pendingShoppingItems: 5))
              .any((i) => i.id == 'pending_shopping'),
          true);
    });

    test('her şey temizse → all_clear achievement', () {
      final r = engine.generate(const FamilySnapshot());
      expect(r.any((i) => i.id == 'all_clear'), true);
      expect(r.first.type, isNotNull);
    });

    test('geciken varsa pending_tasks üretilmez (çift gösterim yok)', () {
      final r = engine
          .generate(const FamilySnapshot(overdueTasks: 1, pendingTasks: 5));
      expect(r.any((i) => i.id == 'pending_tasks'), false);
      expect(r.any((i) => i.id == 'overdue_tasks'), true);
    });

    test('içgörüler öncelik sırasına göre (kritik/yüksek önce)', () {
      final r = engine.generate(const FamilySnapshot(
          overdueTasks: 1, todayEvents: 2, pendingShoppingItems: 4));
      for (var i = 0; i < r.length - 1; i++) {
        expect(r[i].priorityScore <= r[i + 1].priorityScore, true);
      }
    });

    test('çapraz modül: yoğun gün (takvim×görev) → cross_busy_day', () {
      final r = engine
          .generate(const FamilySnapshot(todayEvents: 2, pendingTasks: 3));
      final ins = r.firstWhere((i) => i.id == 'cross_busy_day');
      expect(ins.priority, InsightPriority.high);
      expect(ins.args['events'], '2');
      expect(ins.args['tasks'], '3');
      // Eşik altında üretilmez
      expect(
          engine
              .generate(const FamilySnapshot(todayEvents: 1, pendingTasks: 3))
              .any((i) => i.id == 'cross_busy_day'),
          false);
    });

    test('çapraz modül: alışveriş paylaşımı (alışveriş×aile) eşiği', () {
      expect(
          engine
              .generate(const FamilySnapshot(
                  pendingShoppingItems: 3, memberCount: 2))
              .any((i) => i.id == 'cross_shopping_share'),
          true);
      // Tek üyeyle üretilmez
      expect(
          engine
              .generate(const FamilySnapshot(
                  pendingShoppingItems: 3, memberCount: 1))
              .any((i) => i.id == 'cross_shopping_share'),
          false);
    });

    test('deduplicate — aynı id iki kez gelmez', () {
      final r = engine.generate(const FamilySnapshot(overdueTasks: 2));
      final ids = r.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
