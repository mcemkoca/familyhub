# 📡 API Dokümantasyonu

## Supabase (Primary Backend)

### Authentication

| Endpoint | Method | Açıklama |
|----------|--------|----------|
| `/auth/v1/signup` | POST | Yeni kullanıcı kaydı |
| `/auth/v1/token?grant_type=password` | POST | Email/şifre ile giriş |
| `/auth/v1/token?grant_type=refresh_token` | POST | Token yenileme |
| `/auth/v1/logout` | POST | Çıkış yap |
| `/auth/v1/user` | GET | Mevcut kullanıcı bilgisi |
| `/auth/v1/verify` | POST | Email doğrulama |
| `/auth/v1/recover` | POST | Şifre sıfırlama |

### Database (REST)

Base URL: `https://<project>.supabase.co/rest/v1/`

| Tablo | Endpoint | İzinler |
|-------|----------|---------|
| `profiles` | `/profiles` | Select: own / family members |
| `families` | `/families` | CRUD: admin only |
| `family_members` | `/family_members` | CRUD: family admin |
| `events` | `/events` | CRUD: family members |
| `tasks` | `/tasks` | CRUD: family members |
| `messages` | `/messages` | CRUD: family members |
| `budget_entries` | `/budget_entries` | CRUD: family members |
| `geolocations` | `/geolocations` | Insert: own / Select: family |
| `activity_logs` | `/activity_logs` | Insert: own / Select: admin |

### Realtime (WebSocket)

```javascript
// JavaScript örneği
const channel = supabase
  .channel('family_messages')
  .on('postgres_changes', 
    { event: 'INSERT', schema: 'public', table: 'messages' },
    (payload) => console.log('Yeni mesaj:', payload.new)
  )
  .subscribe();
```

### Storage

| Bucket | Kullanım | Policy |
|--------|----------|--------|
| `avatars` | Profil fotoğrafları | Public read, auth write |
| `documents` | Aile belgeleri | Family members only |
| `voice_messages` | Sesli mesajlar | Family members only |

### RPC Functions

```sql
-- Çocuk PIN doğrulama
select * from verify_child_pin(p_child_id uuid, p_pin text);

-- Kullanıcı hesabı silme
select * from delete_user_account(p_user_id uuid);

-- Admin kontrolü
select * from is_family_admin(p_user_id uuid, p_family_id uuid);

-- Premium kontrolü
select * from can_access_feature(p_user_id uuid, p_feature text);
```

## Firebase

### Cloud Messaging

```dart
// Token alma
final token = await FirebaseMessaging.instance.getToken();

// Topic'e abone olma
await FirebaseMessaging.instance.subscribeToTopic('family_${familyId}');

// Foreground mesaj dinleme
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  NotificationService.showLocalNotification(message);
});
```

### Analytics

| Event | Trigger |
|-------|---------|
| `login` | Başarılı giriş |
| `sign_up` | Yeni kayıt |
| `screen_view` | Ekran değişimi |
| `purchase` | Abonelik satın alma |
| `share` | İçerik paylaşımı |

## AI Services

### OpenAI

```dart
final response = await AIEngine.instance.generateResponse(
  prompt: 'Aile etkinlikleri öner',
  model: AIModel.gpt4o,
);
```

### Google Gemini

```dart
final response = await AIEngine.instance.generateResponse(
  prompt: 'Çocuklar için güvenlik ipuçları',
  model: AIModel.geminiPro,
);
```

## Stripe

| Endpoint | Açıklama |
|----------|----------|
| `/v1/payment_intents` | Ödeme başlatma |
| `/v1/customers` | Müşteri oluşturma |
| `/v1/subscriptions` | Abonelik yönetimi |

## RevenueCat

```dart
// Ürünleri getir
final offerings = await Purchases.getOfferings();

// Satın alma
final customerInfo = await Purchases.purchasePackage(package);

// Abonelik durumu
final customerInfo = await Purchases.getCustomerInfo();
final isPremium = customerInfo.entitlements.active.containsKey('premium');
```

---

*API değişiklikleri için [API.md](https://github.com/mcemkoca/familyhub/blob/main/API.md) dosyasına bakın.*
