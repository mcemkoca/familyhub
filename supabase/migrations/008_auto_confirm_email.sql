-- Auto-confirm new users to bypass email verification
-- This allows immediate signIn after signUp

-- 1. Create function to auto-confirm email on user creation
create or replace function public.auto_confirm_email()
returns trigger as $$
begin
  update auth.users set email_confirmed_at = now() where id = new.id;
  return new;
end;
$$ language plpgsql security definer;

-- 2. Drop existing trigger if present
drop trigger if exists on_auth_user_created on auth.users;

-- 3. Attach trigger to auth.users
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.auto_confirm_email();

-- 4. Confirm existing demo user (if already created without confirmation)
update auth.users 
set email_confirmed_at = now() 
where email = 'mcemkoca0@gmail.com';

-- 5. Optional: also update metadata to mark as confirmed
update auth.users
set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"email_confirmed": true}'::jsonb
where email = 'mcemkoca0@gmail.com';
