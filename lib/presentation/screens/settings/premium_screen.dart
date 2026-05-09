import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/supabase_client.dart';
import '../../../config/constants.dart';
import '../../../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class PremiumPlan {
  final String id;
  final String name;
  final String price;
  final List<String> features;
  final bool isPopular;
  final String? stripePriceId;

  const PremiumPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    this.isPopular = false,
    this.stripePriceId,
  });
}

final _premiumPlansProvider = FutureProvider<List<PremiumPlan>>((ref) async {
  // Gerçek uygulamada bu veri Supabase'den çekilebilir
  return const [
    PremiumPlan(
      id: 'free',
      name: 'Ücretsiz',
      price: '€0',
      features: ['4 aile üyesi', 'Temel görevler', '1 GB depolama'],
    ),
    PremiumPlan(
      id: 'premium',
      name: 'Premium',
      price: '€4.99/ay',
      features: [
        '8 aile üyesi',
        'Gelişmiş bütçe',
        '10 GB depolama',
        'Özel temalar'
      ],
      isPopular: true,
      stripePriceId: 'price_premium_2026',
    ),
    PremiumPlan(
      id: 'family',
      name: 'Aile',
      price: '€9.99/ay',
      features: [
        '20 aile üyesi',
        'Sınırsız depolama',
        'Öncelikli destek',
        'API erişimi'
      ],
      stripePriceId: 'price_family_2026',
    ),
  ];
});

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;

  Future<void> _upgrade(PremiumPlan plan) async {
    if (plan.id == 'free') return;

    setState(() => _isLoading = true);

    final isAdmin = await AuthService.isAdmin();
    if (isAdmin) {
      try {
        await _activatePremium(plan.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).adminHesabiPremiumAktif),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(isPremiumProvider);
        }
      } catch (_) {
        // ignore
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    try {
      await _payWithStripe(plan);
    } catch (e) {
      debugPrint('Stripe ödeme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme başarısız: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payWithStripe(PremiumPlan plan) async {
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('Oturum açık değil');

    String? clientSecret;
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'create-payment-intent',
        body: {'price_id': plan.stripePriceId, 'user_id': userId},
      );
      clientSecret = (response.data as Map<String, dynamic>)['client_secret'] as String?;
    } catch (_) {
      // Edge Function yoksa — test modu: doğrudan aktive et
      await _activatePremium(plan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).testModuPremiumAktiflestirildi),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(isPremiumProvider);
      }
      return;
    }

    if (clientSecret == null) throw Exception('Ödeme bilgisi alınamadı');

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'FamilyHub',
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    // Ödeme başarılı — kayıt ekle
    await _activatePremium(plan.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).premiumAktiflestirildi),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(isPremiumProvider);
    }
  }

  Future<void> _activatePremium(String tier) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    final supabase = SupabaseConfig.client;

    await supabase.from('subscriptions').insert({
      'user_id': userId,
      'subscription_tier': tier,
      'amount': tier == 'family' ? 9.99 : 4.99,
      'currency': 'EUR',
      'status': 'active',
      'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    });

    await supabase.from('profiles').update({
      'is_premium': true,
      'subscription_tier': tier,
      'subscription_expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final premiumAsync = ref.watch(isPremiumProvider);
    final plansAsync = ref.watch(_premiumPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Planlar'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          premiumAsync.when(
            data: (isPremium) => isPremium
                ? Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Chip(
                      label: Text(AppLocalizations.of(context).premium),
                      backgroundColor: AppColors.success,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: plansAsync.when(
        data: (plans) => ListView(
          padding: const EdgeInsets.all(20),
          children: plans.map((plan) {
            final isPopular = plan.isPopular;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: isPopular
                    ? Border.all(color: AppColors.purple, width: 2)
                    : Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'En Popüler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.price,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...plan.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(f),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: plan.id != 'free' && !_isLoading ? () => _upgrade(plan) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular ? AppColors.purple : AppColors.border,
                        foregroundColor: isPopular ? Colors.white : AppColors.dark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(plan.id == 'free' ? 'Seç' : 'Yükselt'),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(AppLocalizations.of(context).planlarYuklenemedi)),
      ),
    );
  }
}
