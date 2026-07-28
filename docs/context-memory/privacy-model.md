# Context Memory — Gizlilik Modeli

## Değişmez kurallar (kodda + testte kilitli)

| Kural | Nerede |
|---|---|
| Credential/prohibited ASLA saklanmaz | `evaluateStoragePolicy` + DB CHECK kısıtı |
| Hassas veri varsayılan KAPALI | `MemoryConsentSnapshot.sensitiveMemoryEnabled=false` + DB default false |
| Başka yetişkinin özel kaydı görünmez | `viewerCanAccess` + RLS `ctx_mem_select` |
| Çocuk kaydı yalnızca ebeveyn/admin | `viewerCanAccess` + RLS rol kontrolü |
| `family_id` istemciden kabul edilmez | RLS `family_members` doğrulaması |
| deviceLocal/session buluta gitmez | `MemoryScope.isSyncable` + DB CHECK (o değerler yok) |
| Hesap değişiminde sızıntı yok | `MemoryKeyspace.belongsTo` (kullanıcı-izole anahtar) |
| Silinen kayıt geri gelmez | `context_memory_tombstones` |
| AI çıkarımı gerçek bilgi değildir | `sourceType.authority` + güven eşiği |
| Niyet ≠ sonuç | `ActionExecutionStatus.isRealSuccess` |

## Sunucuda ne tutulur?

- **Hassas kayıtlar**: `content_encrypted` (istemcide şifreli), `search_text` **NULL**.
- **Normal kayıtlar**: `search_text` doldurulabilir (arama için).
- Loglarda: yalnızca ID/durum/süre — içerik, sağlık verisi, konum, token ASLA.

## GDPR kontrolleri

`context_memory_consents` — modül bazlı izin, hassas veri izni, aile paylaşımı,
bulut senkronu. `purge_context_memory(user)` hesap silmede tüm veriyi temizler
(security definer + `auth.uid()` doğrulaması ile başkasının verisi silinemez).
