-- ============================================================================
-- 065 — shopping_items.unit kolonu (ölçü birimi, stable key)
-- ----------------------------------------------------------------------------
-- AMAÇ: Alışveriş ürünlerine ölçü birimi (adet/kg/L/paket…) desteği. Birim
--       ÇEVRİLMİŞ metin olarak DEĞİL, stable enum key olarak saklanır
--       ('piece','pack','box','bottle','jar','liter','milliliter','kilogram',
--        'gram','bunch','dozen','portion'). UI'da lokalize gösterilir.
-- GÜVENLİ: additive + idempotent. Mevcut satırlar varsayılan 'piece' alır.
--          Kolon eklenmeden önce uygulama unit'siz de sorunsuz çalışır
--          (repository unit'i defensive okur, insert'i unit'siz retry eder).
-- ============================================================================

alter table public.shopping_items
  add column if not exists unit text not null default 'piece';

-- Bilinmeyen/eski değerleri güvenli aralığa çek (idempotent).
update public.shopping_items
   set unit = 'piece'
 where unit is null
    or unit not in ('piece','pack','box','bottle','jar','liter',
                    'milliliter','kilogram','gram','bunch','dozen','portion');
