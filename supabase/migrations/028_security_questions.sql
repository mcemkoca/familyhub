-- Migration 028: Add security questions and email to profiles table
-- Enables in-app password reset with security question verification

-- 1. Ensure email column exists (app inserts it but schema may not declare it)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. Add security question columns (answers stored as bcrypt hashes)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS security_question_1 TEXT;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS security_answer_1 TEXT;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS security_question_2 TEXT;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS security_answer_2 TEXT;

-- Ensure pgcrypto is available and search_path includes extensions schema
SET search_path = public, extensions;

-- Hash existing plaintext answers (one-time migration)
DO $$
BEGIN
  UPDATE public.profiles
  SET security_answer_1 = crypt(security_answer_1, gen_salt('bf'))
  WHERE security_answer_1 IS NOT NULL AND length(security_answer_1) < 60;

  UPDATE public.profiles
  SET security_answer_2 = crypt(security_answer_2, gen_salt('bf'))
  WHERE security_answer_2 IS NOT NULL AND length(security_answer_2) < 60;
EXCEPTION WHEN undefined_function THEN
  -- pgcrypto not available, skip hashing
  NULL;
END $$;

-- 3. Create index on email for forgot-password lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- 4. Update RLS: allow anyone to read security questions by email (needed for forgot-password flow)
-- The existing "Profiles are viewable by everyone" SELECT policy already handles this.
-- Ensure update policy allows users to update their own security questions.
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- 5. RPC: verify security answers server-side with pgcrypto
CREATE OR REPLACE FUNCTION public.verify_security_answers(
  p_email TEXT,
  p_answer1 TEXT,
  p_answer2 TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile RECORD;
BEGIN
  SELECT security_answer_1, security_answer_2 INTO v_profile
  FROM public.profiles
  WHERE email = p_email;

  IF v_profile IS NULL OR v_profile.security_answer_1 IS NULL OR v_profile.security_answer_2 IS NULL THEN
    RETURN false;
  END IF;

  RETURN crypt(p_answer1, v_profile.security_answer_1) = v_profile.security_answer_1
     AND crypt(p_answer2, v_profile.security_answer_2) = v_profile.security_answer_2;
END;
$$;

-- 6. RPC: update security questions with automatic hashing
CREATE OR REPLACE FUNCTION public.update_security_questions(
  p_user_id UUID,
  p_question1 TEXT,
  p_answer1 TEXT,
  p_question2 TEXT,
  p_answer2 TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET
    security_question_1 = p_question1,
    security_answer_1 = crypt(p_answer1, gen_salt('bf')),
    security_question_2 = p_question2,
    security_answer_2 = crypt(p_answer2, gen_salt('bf')),
    updated_at = NOW()
  WHERE id = p_user_id;
END;
$$;
