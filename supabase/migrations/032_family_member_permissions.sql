-- Add permissions JSONB column to family_members
ALTER TABLE public.family_members ADD COLUMN IF NOT EXISTS permissions jsonb DEFAULT '{}';

-- Helper function to check admin status without RLS recursion
CREATE OR REPLACE FUNCTION public.is_family_admin(p_family_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.family_members fm
    WHERE fm.family_id = p_family_id
      AND fm.user_id = auth.uid()
      AND fm.role = 'admin'
  );
END;
$$;

-- Update RLS to allow admins to update permissions
DROP POLICY IF EXISTS "Family members updatable by admin" ON public.family_members;
CREATE POLICY "Family members updatable by admin"
  ON public.family_members FOR UPDATE TO authenticated
  USING (public.is_family_admin(family_members.family_id));
