import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/supabase_client.dart';
import '../../../config/constants.dart';
import '../../../repositories/subscription_repository.dart';
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
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          ref.invalidate(isPremiumProvider);
        }
      } catch (e) {
        debugPrint('Admin premium activation error: $e');
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
    } catch (e) {
      debugPrint('Stripe edge function error: $e');
      // Edge Function yoksa — test modu: doğrudan aktive et
      await _activatePremium(plan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).testModuPremiumAktiflestirildi),
            backgroundColor: const Color(0xFF10B981),
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
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      ref.invalidate(isPremiumProvider);
    }
  }

  Future<void> _activatePremium(String tier) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;
    await SubscriptionRepository().activatePremium(userId, tier);
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.only(right: 16),
                    child: Chip(
                      label: Text(AppLocalizations.of(context).premium),
                      backgroundColor: const Color(0xFF10B981),
                      labelStyle: const TextStyle(color: Colors.white),
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
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(20),
                border: isPopular
                    ? Border.all(color: const Color(0xFF8B5CF6), width: 2)
                    : Border.all(
                        color: const Color(0x1EFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
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
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...plan.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
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
                        backgroundColor: isPopular ? const Color(0xFF8B5CF6) : const Color(0x1EFFFFFF),
                        foregroundColor: isPopular ? Colors.white : const Color(0xFFE5E7EB),
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
