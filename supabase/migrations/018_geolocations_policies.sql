-- Geolocations RLS Policies: Fix missing authenticated policies + child_id support

-- Authenticated parents can view all family geolocations
DROP POLICY IF EXISTS "Parent can view family geolocations" ON public.geolocations;
CREATE POLICY "Parent can view family geolocations"
  ON public.geolocations FOR SELECT TO authenticated
  USING (family_id IN (
    SELECT family_id FROM public.profiles WHERE id = auth.uid()
  ));

-- Authenticated parents can insert geolocations for their family
DROP POLICY IF EXISTS "Parent can insert family geolocations" ON public.geolocations;
CREATE POLICY "Parent can insert family geolocations"
  ON public.geolocations FOR INSERT TO authenticated
  WITH CHECK (family_id IN (
    SELECT family_id FROM public.profiles WHERE id = auth.uid()
  ));

-- Authenticated parents can update their own geolocations
DROP POLICY IF EXISTS "Parent can update own geolocations" ON public.geolocations;
CREATE POLICY "Parent can update own geolocations"
  ON public.geolocations FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Authenticated parents can delete their own geolocations
DROP POLICY IF EXISTS "Parent can delete own geolocations" ON public.geolocations;
CREATE POLICY "Parent can delete own geolocations"
  ON public.geolocations FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- Anon child can insert with child_id (already in 015, but ensure it exists)
DROP POLICY IF EXISTS "Anon child can share location" ON public.geolocations;
CREATE POLICY "Anon child can share location"
  ON public.geolocations FOR INSERT TO anon
  WITH CHECK (child_id IN (
    SELECT id FROM public.child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
  ));

-- Anon child can view family geolocations (already in 015, but ensure it exists)
DROP POLICY IF EXISTS "Anon child can view family geolocations" ON public.geolocations;
CREATE POLICY "Anon child can view family geolocations"
  ON public.geolocations FOR SELECT TO anon
  USING (family_id IN (
    SELECT family_id FROM public.child_accounts WHERE id = nullif(current_setting('app.current_child_id', true), '')::uuid
  ));
