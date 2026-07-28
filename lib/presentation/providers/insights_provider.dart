import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../config/routes.dart';
import '../../domain/entities.dart';
import 'app_providers.dart';
import '../screens/budget/subscription_screen.dart' show subscriptionProvider;
import '../screens/child/child_development_screen.dart' show childDevProvider;
import '../screens/child/child_dev_store.dart';

/// Aile için tek bir akıllı içgörü/uyarı.
class Insight {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? route;
  final int severity; // 0 bilgi, 1 öneri, 2 uyarı
  const Insight({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.route,
    this.severity = 0,
  });
}

/// Gerçek yerel verilerden (bütçe, giderler, gelişim, alışveriş) kural tabanlı
/// akıllı uyarılar üretir. Tümü çevrimdışı çalışır; en önemliler önce sıralanır.
final familyInsightsProvider = Provider<List<Insight>>((ref) {
  final insights = <Insight>[];
  final now = DateTime.now();
  // Locale-aware l10n — provider'da BuildContext yok; localeProvider'ı izleyip
  // senkron lookupAppLocalizations ile çeviriyi alıyoruz (dil değişince yeniden
  // hesaplanır).
  final l = lookupAppLocalizations(ref.watch(localeProvider));

  // ── Bütçe: bu ayki gelir/gider dengesi ──
  final txs = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final monthTxs = txs.where(
    (t) => t.createdAt.year == now.year && t.createdAt.month == now.month,
  );
  final income = monthTxs
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0, (s, t) => s + t.amount);
  final expense = monthTxs
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (s, t) => s + t.amount);

  if (income > 0 && expense > income * 0.9) {
    insights.add(
      Insight(
        icon: Icons.trending_down_rounded,
        color: const Color(0xFFEF4444),
        title: l.insightSpendingHighTitle,
        message: l.insightSpendingHighMsg(
          expense.toStringAsFixed(0),
          income.toStringAsFixed(0),
          ((expense / income) * 100).round(),
        ),
        route: AppRoutes.budget,
        severity: 2,
      ),
    );
  } else if (income > 0 && expense < income * 0.6) {
    insights.add(
      Insight(
        icon: Icons.savings_rounded,
        color: const Color(0xFF22C55E),
        title: l.insightSavingTitle,
        message: l.insightSavingMsg(
          (((income - expense) / income) * 100).round(),
        ),
        route: AppRoutes.budget,
        severity: 0,
      ),
    );
  }

  // ── Ev Giderleri: aylık sabit gider toplamı ──
  final subs = ref.watch(subscriptionProvider);
  final activeSubs = subs.where((s) => s.active).toList();
  if (activeSubs.isNotEmpty) {
    final monthlyFixed = activeSubs.fold<double>(
      0,
      (s, x) => s + x.monthlyAmount,
    );
    // Bir sonraki 7 gün içinde yenilenecek olanlar.
    insights.add(
      Insight(
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF6366F1),
        title: l.insightFixedTitle,
        message: l.insightFixedMsg(
          activeSubs.length,
          monthlyFixed.toStringAsFixed(0),
        ),
        route: AppRoutes.subscriptions,
        severity: 0,
      ),
    );
  }

  // ── Gelişim: değerlendirme eksik çocuklar ──
  final children = ref.watch(childDevProvider);
  for (final child in children) {
    final progress = DevStore.assessmentProgress(child.id, child.devGroup);
    if (progress < 0.05) {
      insights.add(
        Insight(
          icon: Icons.child_care_rounded,
          color: const Color(0xFFF43F5E),
          title: l.insightChildAssessTitle(child.name),
          message: l.insightChildAssessMsg(child.name),
          route: AppRoutes.childDevelopment,
          severity: 1,
        ),
      );
    }
  }

  // ── Alışveriş: liste boşsa öner ──
  final shopping = ref.watch(shoppingItemsProvider).valueOrNull ?? const [];
  final pending = shopping.where((i) => !i.isCompleted).length;
  if (shopping.isEmpty) {
    insights.add(
      Insight(
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF10B981),
        title: l.insightShoppingEmptyTitle,
        message: l.insightShoppingEmptyMsg,
        route: AppRoutes.shopping,
        severity: 1,
      ),
    );
  } else if (pending > 8) {
    insights.add(
      Insight(
        icon: Icons.shopping_cart_checkout_rounded,
        color: const Color(0xFF10B981),
        title: l.insightShoppingTimeTitle,
        message: l.insightShoppingTimeMsg(pending),
        route: AppRoutes.shopping,
        severity: 1,
      ),
    );
  }

  // En önemliler (yüksek severity) önce.
  insights.sort((a, b) => b.severity.compareTo(a.severity));
  return insights;
});
