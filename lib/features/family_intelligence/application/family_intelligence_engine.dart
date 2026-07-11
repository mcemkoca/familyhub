import '../../../config/routes.dart';
import '../domain/family_insight.dart';

/// Kural motoruna giden özet aile verisi (modül provider'larından toplanır).
/// Saf veri → motor deterministik + test edilebilir olur.
class FamilySnapshot {
  final int overdueTasks;
  final int pendingTasks;
  final int todayEvents;
  final int pendingShoppingItems;
  final int upcomingPaymentDays; // -1 → yaklaşan ödeme yok
  final int memberCount;

  const FamilySnapshot({
    this.overdueTasks = 0,
    this.pendingTasks = 0,
    this.todayEvents = 0,
    this.pendingShoppingItems = 0,
    this.upcomingPaymentDays = -1,
    this.memberCount = 0,
  });
}

/// Deterministik kural tabanlı içgörü motoru — AI GEREKTİRMEZ.
/// AI yalnızca bu doğrulanmış çıktıyı özetlemek için (opsiyonel) kullanılabilir;
/// olmayan olay/veri ÜRETMEZ.
class FamilyIntelligenceEngine {
  const FamilyIntelligenceEngine();

  List<FamilyInsight> generate(FamilySnapshot s) {
    final out = <FamilyInsight>[];

    // Geciken görevler → yüksek öncelik
    if (s.overdueTasks > 0) {
      out.add(FamilyInsight(
        id: 'overdue_tasks',
        type: InsightType.warning,
        module: InsightModule.tasks,
        priority: InsightPriority.high,
        titleKey: 'fiInsightOverdueTitle',
        bodyKey: 'fiInsightOverdueBody',
        args: {'count': '${s.overdueTasks}'},
        reasonKey: 'fiReasonOverdue',
        actionRoute: AppRoutes.tasks,
      ));
    }

    // Yaklaşan ödeme (<=3 gün) → yüksek
    if (s.upcomingPaymentDays >= 0 && s.upcomingPaymentDays <= 3) {
      out.add(FamilyInsight(
        id: 'upcoming_payment',
        type: InsightType.reminder,
        module: InsightModule.budget,
        priority: InsightPriority.high,
        titleKey: 'fiInsightPaymentTitle',
        bodyKey: 'fiInsightPaymentBody',
        args: {'days': '${s.upcomingPaymentDays}'},
        reasonKey: 'fiReasonPayment',
        actionRoute: AppRoutes.budget,
      ));
    }

    // Bugünkü etkinlikler → normal
    if (s.todayEvents > 0) {
      out.add(FamilyInsight(
        id: 'today_events',
        type: InsightType.summary,
        module: InsightModule.calendar,
        priority: InsightPriority.normal,
        titleKey: 'fiInsightTodayEventsTitle',
        bodyKey: 'fiInsightTodayEventsBody',
        args: {'count': '${s.todayEvents}'},
        reasonKey: 'fiReasonTodayEvents',
        actionRoute: AppRoutes.calendar,
      ));
    }

    // Bekleyen alışveriş (>=3) → normal
    if (s.pendingShoppingItems >= 3) {
      out.add(FamilyInsight(
        id: 'pending_shopping',
        type: InsightType.recommendation,
        module: InsightModule.shopping,
        priority: InsightPriority.normal,
        titleKey: 'fiInsightShoppingTitle',
        bodyKey: 'fiInsightShoppingBody',
        args: {'count': '${s.pendingShoppingItems}'},
        reasonKey: 'fiReasonShopping',
        actionRoute: AppRoutes.shopping,
      ));
    }

    // Bekleyen görevler (geciken yoksa) → bilgilendirme
    if (s.overdueTasks == 0 && s.pendingTasks > 0) {
      out.add(FamilyInsight(
        id: 'pending_tasks',
        type: InsightType.summary,
        module: InsightModule.tasks,
        priority: InsightPriority.info,
        titleKey: 'fiInsightPendingTasksTitle',
        bodyKey: 'fiInsightPendingTasksBody',
        args: {'count': '${s.pendingTasks}'},
        reasonKey: 'fiReasonPendingTasks',
        actionRoute: AppRoutes.tasks,
      ));
    }

    // ── Çapraz modül içgörüleri (iki modülün sinyalini birleştirir) ──
    // Takvim × Görevler: yoğun gün + bekleyen görev → dağıtım öner.
    if (s.todayEvents >= 2 && s.pendingTasks >= 3) {
      out.add(FamilyInsight(
        id: 'cross_busy_day',
        type: InsightType.planning,
        module: InsightModule.calendar,
        priority: InsightPriority.high,
        titleKey: 'fiInsightBusyDayTitle',
        bodyKey: 'fiInsightBusyDayBody',
        args: {'events': '${s.todayEvents}', 'tasks': '${s.pendingTasks}'},
        reasonKey: 'fiReasonBusyDay',
        actionRoute: AppRoutes.tasks,
      ));
    }
    // Alışveriş × Aile: liste dolu + birden fazla üye → paylaşım öner.
    if (s.pendingShoppingItems >= 3 && s.memberCount >= 2) {
      out.add(FamilyInsight(
        id: 'cross_shopping_share',
        type: InsightType.recommendation,
        module: InsightModule.shopping,
        priority: InsightPriority.normal,
        titleKey: 'fiInsightShareShoppingTitle',
        bodyKey: 'fiInsightShareShoppingBody',
        args: {'count': '${s.pendingShoppingItems}'},
        reasonKey: 'fiReasonShareShopping',
        actionRoute: AppRoutes.shopping,
      ));
    }

    // Her şey temizse → başarı (pozitif içgörü)
    if (s.overdueTasks == 0 &&
        s.pendingTasks == 0 &&
        s.pendingShoppingItems == 0) {
      out.add(const FamilyInsight(
        id: 'all_clear',
        type: InsightType.achievement,
        module: InsightModule.general,
        priority: InsightPriority.info,
        titleKey: 'fiInsightAllClearTitle',
        bodyKey: 'fiInsightAllClearBody',
        reasonKey: 'fiReasonAllClear',
      ));
    }

    // Öncelik sırasına göre sırala (kritik önce), id ile deduplicate.
    final seen = <String>{};
    out.retainWhere((i) => seen.add(i.id));
    out.sort((a, b) => a.priorityScore.compareTo(b.priorityScore));
    return out;
  }
}
