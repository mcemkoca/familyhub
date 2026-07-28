-- CANLI messages TABLOSU — GERÇEK KOLON LİSTESİ
-- Hiçbir kolon adı varsaymaz; yalnızca information_schema kullanır.
-- Supabase Dashboard → SQL Editor → yapıştır → Run → çıktının TAMAMINI paylaş.

select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'messages'
order by ordinal_position;
