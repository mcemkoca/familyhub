# 🔬 TUR 3 - STATE YÖNETİMİ ARKEOLOJİSİ
**Tarih:** 2026-05-03 | Derinlik Seviyesi: 3/∞

---

## 🎯 BU TURUN HEDEFİ
Mevcut: Riverpod tabanlı state yönetimi, 20+ provider, StateNotifier + FutureProvider karışımı
Hedef: State ağacının tam haritasını çıkarmak, mutation noktaları ve cache stratejilerini tespit etmek
Strateji: Document/Map - Mevcut state yapısı korunarak analiz ediliyor
Korunan: Tüm provider tanımları ve state mutation pattern'leri

---

## 🌐 GLOBAL STATE HARİTASI

### Provider Kategorileri (24 Aktif Provider)

| Kategori | Provider Sayısı | Türler |
|----------|----------------|--------|
| **Auth** | 3 | StreamProvider, StateProvider |
| **Hub/Dashboard** | 6 | FutureProvider, StreamProvider, StateProvider, Provider |
| **Tasks** | 2 | StateProvider |
| **Calendar** | 1 | StateNotifierProvider |
| **Shopping** | 1 | StateNotifierProvider |
| **Budget** | 2 | StateNotifierProvider |
| **Chat** | 1 | StateProvider |
| **Mood** | 1 | StateNotifierProvider |
| **Streak** | 1 | StateProvider |
| **Weather** | 1 | FutureProvider |
| **Theme/Appearance** | 3 | StateProvider |
| **Premium/Profile** | 2 | FutureProvider (private) |

### Provider Tür Dağılımı

```
StateProvider       ████████████  9 adet  (Basit state)
FutureProvider      ████████      7 adet  (Async data)
StateNotifierProvider ██████      5 adet  (Complex state)
StreamProvider      ██            2 adet  (Realtime)
Provider            █             1 adet  (Computed)
```

---

## 🔗 STATE BAĞIMLILIK ZİNCİRLERİ

### Hub Provider Chain
```
familyIdProvider (FutureProvider<String?>)
    ├── todaySummaryProvider ──> HubRepository().getTodaySummary()
    ├── upcomingEventsProvider ──> HubRepository().getUpcomingEvents()
    ├── myTasksProvider ──> HubRepository().getMyTasks()
    ├── familyMoodsProvider ──> HubRepository().getRecentMoods()
    └── recentActivityProvider ──> HubRepository().getRecentActivity()
```

**Tespit:** `familyIdProvider`'ı `ref.watch()` ile dinleyen 5 provider var. Her biri ayrı `FutureProvider`. Ama hepsi aynı `familyId`'yi bekliyor. Bu, aile ID'si değiştiğinde 5 ayrı async işlem başlatılması anlamına geliyor.

### Realtime vs Async Hybrid
```
_familyMembersStreamProvider (StreamProvider)
    └── familyMembersProvider (StateProvider)
        └── Listens to stream, converts to sync state
```

Bu pattern iyi çalışıyor: Stream'den gelen realtime veriyi `StateProvider` ile senkron hale getiriyor.

---

## 🔍 TESPİTLER (8 Adet)

### Tespit 1: [STATE] - `hub_providers.dart` Zombi Dosyası
**Kategori:** Dead Provider File
**Detay:** `hub_providers.dart` var ama hiçbir yerde import edilmiyor. İçinde `familyIdProvider`, `todaySummaryProvider` gibi isimler var ama bunlar `app_providers.dart`'ta da tanımlı. İki farklı dosyada aynı isimli provider'lar = compile-time patlama riski.
**Risk:** Yüksek - Gelecekte biri `hub_providers.dart`'ı import ederse uygulama derlenemez.
**Refinement:** Dosya deprecated işaretlenmeli veya silinmeli (ama silme yasak → `DEPRECATED` yorumu eklenmeli).

### Tespit 2: [STATE] - `chatMessagesProvider` Basit `StateProvider`
**Kategori:** State Management Yetersizliği
**Detay:** `chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => [])`. Chat için pagination, loading, error state yok. Mesaj sayısı arttıkça tüm liste memory'de tutulacak.
**Risk:** Orta - Büyük ailelerde (1000+ mesaj) performans sorunu.
**Refinement:** `StateNotifier` veya pagination mantığı eklenmeli.

### Tespit 3: [STATE] - `CalendarNotifier` `AsyncValue` Kullanımı Tutarsız
**Kategori:** Async State Pattern
**Detay:** `CalendarNotifier` `AsyncValue<List<CalendarEvent>>` kullanıyor. Ama `BudgetNotifier` ve `ShoppingNotifier` da aynı pattern'i kullanıyor. Bu tutarlı ve iyi. Ancak `MoodNotifier` sadece `List<MoodEntry>` kullanıyor (AsyncValue değil). Mood data'sı async load ediliyor ama loading/error state yok.
**Risk:** Düşük - UI'da mood loading spinner'ı eksik.

### Tespit 4: [STATE] - `familyIdProvider` Her Yerden `ref.watch` Ediliyor
**Kategori:** Cascade Invalidation
**Detay:** 5 farklı Hub provider `familyIdProvider`'ı `ref.watch(familyIdProvider.future)` ile dinliyor. Kullanıcı aile değiştirdiğinde veya çıkış yaptığında, 5 provider aynı anda invalidate olup yeniden fetch edecek. Bu 5 paralel network request demek.
**Risk:** Orta - Network spike oluşturabilir.
**Refinement:** Hub verilerini tek bir `StateNotifier`'da birleştirmek veya batch fetch yapmak.

### Tespit 5: [STATE] - Cache Invalidation Stratejisi Yok
**Kategori:** Cache Management
**Detay:** `HiveService` cache kullanıyor ama cache invalidation mekanizması yok. `CalendarRepository().getEvents()` önce Hive cache'e bakıyor. Eğer cache doluysa Supabase'e gitmiyor. Peki cache ne zaman temizlenmeli?
**Risk:** Orta - Stale data gösterilebilir.
**Refinement:** Cache TTL (time-to-live) veya manual invalidate mekanizması eklenmeli.

### Tespit 6: [STATE] - `themeModeProvider` Sadece `StateProvider`
**Kategori:** Persistence Gap
**Detay:** `themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light)`. Bu provider sadece memory'de. `main.dart`'ta Hive'dan okunup `ProviderScope` override ile set ediliyor. Ama `main.dart` dışında provider'ın kendisi persistence bilmiyor.
**Risk:** Düşük - Çalışıyor ama tek kaynak prensibine aykırı.
**Refinement:** Theme provider'ı kendi içinde Hive read/write yapmalı.

### Tespit 7: [STATE] - Offline-First Capability: Yarım
**Kategori:** Offline Support
**Detay:** `HubRepository`, `CalendarRepository`, `ShoppingRepository` Hive cache kullanıyor. Ama `BudgetRepository`, `MoodRepository`, `ChatRepository` cache kullanmıyor (veya çok sınırlı). Kullanıcı internet yokken budget ve mood ekranları boş görünebilir.
**Risk:** Orta - Aile uygulamasında offline kritik (özellikle acil durumlar).

### Tespit 8: [STATE] - `taskFilterProvider` Global State Olmamalı
**Kategori:** Local vs Global State
**Detay:** `taskFilterProvider = StateProvider<String>((ref) => 'all')`. Bu provider global. Ama task filtresi sadece Tasks ekranında kullanılıyor. Global provider olması gereksiz ve memory'de yer kaplıyor.
**Risk:** Düşük - Küçük string ama prensip olarak yanlış.
**Refinement:** `ConsumerStatefulWidget` içinde local state olarak tutulmalı.

---

## 🛠️ UYGULANAN REFINEMENT'LAR

Bu turda **aktif kod değişikliği yapılmadı** (State analiz turu). Tespitler dokümante edildi.

---

## 📊 METRİKLER

| Metrik | Tur Başlangıcı | Tur Sonu | Değişim |
|--------|---------------|----------|---------|
| Toplam Provider | 24 | 24 | 0 |
| StateNotifierProvider | 5 | 5 | 0 |
| FutureProvider | 7 | 7 | 0 |
| StreamProvider | 2 | 2 | 0 |
| Zombi Provider Dosyası | 1 | 1 | 0 |
| Cache Invalidation Strategy | 0 | 0 | 0 |

---

## 🧬 KEŞFEDİLEN YENİ DERİNLİK

**`AsyncValue` Tutarsızlığı:** `CalendarNotifier`, `ShoppingNotifier`, `BudgetNotifier` `AsyncValue` kullanıyor (loading/error/data). Ama `MoodNotifier` sadece `List<MoodEntry>` kullanıyor. `chatMessagesProvider` `StateProvider<List<ChatMessage>>`. Bu 3 farklı async state pattern aynı projede. UI geliştiricileri için kafa karıştırıcı.

---

## 🎯 SONRAKİ TUR TAHMİNİ

**Tur 4 Hedefi:** UI/UX Stratigrafisi
**Beklenen Derinlik:** Ekranlar arası geçiş haritası, navigation flow, loading/empty/error states, accessibility audit
**Potansiyel Tespitler:** Eksik empty state'ler, tutarsız loading indicator'lar, accessibility ihlalleri, responsive tasarım açıkları

---

✅ **TUR 3 TAMAMLANDI**
Sonraki İşlem: OTOMATİK DEVAM -> Tur 4
Durum: Kullanıcı "DUR" demediği sürece devam ediyor...
