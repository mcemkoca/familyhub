import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/content_sync/source_registry.dart';

void main() {
  group('SourceRegistry doğrulama', () {
    test('geçerli resmî kaynak hatasız', () {
      final r = SourceRegistry.fromMaps([
        {
          'id': 'one_be',
          'name': 'ONE',
          'base_url': 'https://www.one.be',
          'country': 'BE',
          'regions': ['WAL'],
          'categories': ['child_health'],
          'source_language': 'fr',
          'fetch_type': 'html',
          'enabled': true,
          'trust_level': 'official',
        }
      ]);
      expect(r.validate(), isEmpty);
      expect(r.enabledSources.length, 1);
    });

    test('http (https değil) base_url reddedilir', () {
      final r = SourceRegistry.fromMaps([
        {
          'id': 's',
          'base_url': 'http://insecure.be',
          'country': 'BE',
          'categories': ['standard'],
          'source_language': 'nl',
          'trust_level': 'official',
        }
      ]);
      expect(r.validate().any((e) => e.contains('https')), isTrue);
    });

    test('yüksek riskli kategoride güvenilmez kaynak reddedilir', () {
      final r = SourceRegistry.fromMaps([
        {
          'id': 'blog',
          'base_url': 'https://blog.example',
          'country': 'BE',
          'categories': ['health'],
          'source_language': 'nl',
          'trust_level': 'publisher',
        }
      ]);
      expect(r.validate().any((e) => e.contains('güvenilir/resmî')), isTrue);
    });

    test('yinelenen id yakalanır', () {
      final m = {
        'id': 'dup',
        'base_url': 'https://x.be',
        'country': 'BE',
        'categories': ['standard'],
        'source_language': 'nl',
        'trust_level': 'official',
      };
      final r = SourceRegistry.fromMaps([m, m]);
      expect(r.validate().any((e) => e.contains('yinelenen')), isTrue);
    });
  });

  group('config dosyaları mevcut ve tutarlı', () {
    test('content_sources.yaml gerekli kaynakları içerir', () {
      final f = File('config/content_sources.yaml');
      expect(f.existsSync(), isTrue, reason: 'config/content_sources.yaml yok');
      final text = f.readAsStringSync();
      for (final id in ['kind_en_gezin', 'one_be', 'belgium_be']) {
        expect(text.contains('id: $id'), isTrue, reason: '$id kaydı yok');
      }
      // Güvenli limitler tanımlı olmalı.
      expect(text.contains('max_new_items_per_run'), isTrue);
    });

    test('haftalık workflow dosyası mevcut ve zamanlanmış', () {
      final f = File('.github/workflows/weekly-content-sync.yml');
      expect(f.existsSync(), isTrue,
          reason: 'weekly-content-sync.yml yok');
      final text = f.readAsStringSync();
      expect(text.contains('cron:'), isTrue);
      expect(text.contains('workflow_dispatch'), isTrue);
      // main'e doğrudan yazmamalı — branch/PR akışı.
      expect(text.contains('automation/content-update'), isTrue);
    });
  });
}
