-- Add accent_color to profiles so theme preferences persist per-profile
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS accent_color TEXT DEFAULT 'cobalt';
