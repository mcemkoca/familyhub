# Context Memory — Mimari (Faz 1 tamamlandı)

## Durum

| Faz | Kapsam | Durum |
|---|---|---|
| 0 | Repository denetimi | ✅ `current-state-audit.md` |
| 1 | Domain foundation (enum + policy + test) | ✅ 30 test geçiyor |
| 2 | Şifreli yerel depo (Hive + secure_storage) | ⏳ |
| 3 | Supabase `context_memories` + RLS | ⏳ |
| 4 | Ingestion pipeline | ⏳ |
| 5 | Retrieval + Context Builder | ⏳ |
| 6 | AI orchestration | ⏳ |
| 7 | Modül adapter'ları | ⏳ |
| 8 | Memory Center UI | ⏳ |
| 9 | Sync + dayanıklılık | ⏳ |
| 10 | Kalite/test | ⏳ |

## Faz 1'de kurulan çekirdek

`lib/features/context_memory/domain/`
- **`memory_enums.dart`** — 7 enum, hepsi güvenli parse (bilinmeyen değer → güvenli varsayılan):
  - `MemoryScope` (+`isSyncable`: deviceLocal/session ASLA senkronize edilmez)
  - `MemoryKind`, `MemoryStatus` (+`isUsableInContext`)
  - `MemorySensitivity` (+`isNeverStorable`, `requiresEncryption`, `requiresExplicitConsent`)
  - `MemorySourceType` (+`authority`: çelişki çözüm sırası)
  - `MemorySyncState`, `ActionExecutionStatus` (+`isRealSuccess`)
- **`memory_policy.dart`** — saf karar fonksiyonları:
  - `evaluateStoragePolicy` — mutlak yasak → consent → modül → güven eşiği sırası
  - `defaultRetention` — türe/hassasiyete göre saklama süresi
  - `newRecordSupersedes` — otorite + zaman ile çelişki çözümü
  - `canIncludeInContext` — bağlama ekleme dört kontrolü
  - `viewerCanAccess` — kapsam bazlı erişim (aile/çocuk/özel izolasyonu)

## Kilitlenen değişmez kurallar (test edilmiş)

1. **Credential/prohibited ASLA saklanmaz** — consent açık olsa bile.
2. **Hassas veri varsayılan KAPALI** — açık izin olmadan sağlık/çocuk/finans/konum saklanmaz.
3. **AI çıkarımı gerçek bilgi değildir** — `aiDerived` + confidence < 0.75 → saklanmaz.
4. **Kullanıcı düzeltmesi her şeyi ezer** — `userCorrection` en yüksek otorite (100).
5. **superseded/disputed/expired ASLA bağlama girmez.**
6. **Başka yetişkinin özel kaydı otomatik görünmez** — aynı ailede bile.
7. **Yalnızca `succeeded` gerçek başarıdır** — niyet ≠ sonuç.

## Sonraki adım (Faz 2)

Şifreli Hive box'ları: `flutter_secure_storage` (repo'da mevcut) ile cihaz anahtarı,
`memory_records_v1` box'ı, `userId` namespace'i (hesap değişiminde sızıntı yok),
schema versioning + corruption recovery.
