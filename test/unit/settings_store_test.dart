import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/settings_store.dart';

/// Ayar deposu — kullanıcı izolasyonu (oturumsuz durum).
///
/// Not: oturumlu senaryo Supabase auth gerektirir; burada anahtar üretiminin
/// kullanıcıya göre ayrıştığı ve oturumsuzda gerçek veriye karışmadığı test
/// edilir. Uçtan uca izolasyon cihaz testinde doğrulanmalıdır.
void main() {
  group('scopedKey — hesap değişimi sızıntısı', () {
    test('oturum yokken _anon soneki kullanılır', () {
      expect(SettingsStore.scopedKey('crash_settings'), 'crash_settings_anon');
    });

    test('farklı ayar grupları farklı anahtar üretir', () {
      expect(
        SettingsStore.scopedKey('crash_settings'),
        isNot(SettingsStore.scopedKey('sos_templates')),
      );
    });

    test('anahtar ayar adını korur (okunabilir/taşınabilir)', () {
      expect(SettingsStore.scopedKey('location_profile'),
          startsWith('location_profile'));
    });

    test('KRİTİK: anahtar asla sabit değil — kullanıcı ayrımı sonekte', () {
      final key = SettingsStore.scopedKey('health_cycle_start');
      // Sabit 'health_cycle_start' OLMAMALI; kullanıcı/anon soneki taşımalı.
      expect(key, isNot('health_cycle_start'));
      expect(key.contains('_'), isTrue);
    });
  });

  group('load — bozuk veri toleransı', () {
    test('kayıt yoksa boş harita (varsayılanlar korunur, crash yok)', () {
      // Hive başlatılmamışken bile çökmemeli.
      expect(SettingsStore.load('hic_olmayan_ayar'), isEmpty);
    });
  });
}
