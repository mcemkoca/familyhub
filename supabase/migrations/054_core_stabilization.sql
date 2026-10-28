-- Core stabilization: atomic registration, chat persistence and authorization.

-- 1. Create profile, family and membership in the same auth transaction.
create or replace function public.handle_new_user()
returns trigger as $$
declare
  v_family_name text := nullif(trim(new.raw_user_meta_data->>'family_name'), '');
  v_family_id uuid;
  v_display_name text := coalesce(
    nullif(trim(new.raw_user_meta_data->>'display_name'), ''),
    split_part(new.email, '@', 1)
  );
begin
  insert into public.profiles (id, display_name, email)
  values (new.id, v_display_name, new.email)
  on conflict (id) do nothing;

  if v_family_name is not null then
    insert into public.families (name, created_by)
    values (v_family_name, new.id)
    returning id into v_family_id;

    insert into public.family_members (
      family_id, user_id, role, display_name
    ) values (
      v_family_id, new.id, 'admin', v_display_name
    );

    update public.profiles
    set family_id = v_family_id
    where id = new.id;
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = '';

-- 2. Align the messages table with the repository while preserving old data.
alter table public.messages add column if not exists content text;
alter table public.messages add column if not exists sender_name text;
alter table public.messages add column if not exists image_url text;
alter table public.messages add column if not exists audio_url text;
alter table public.messages add column if not exists audio_duration integer;
alter table public.messages add column if not exists video_url text;
alter table public.messages add column if not exists file_name text;
alter table public.messages add column if not exists file_size bigint;
alter table public.messages add column if not exists reply_to_id uuid;
alter table public.messages add column if not exists reply_to_content text;
alter table public.messages add column if not exists reply_to_sender text;
alter table public.messages add column if not exists is_pinned boolean default false;
alter table public.messages add column if not exists is_read boolean default false;
alter table public.messages add column if not exists read_count integer default 0;

update public.messages
set content = coalesce(content, text),
    image_url = coalesce(image_url, media_urls[1]),
    reply_to_id = coalesce(reply_to_id, reply_to),
    is_pinned = coalesce(is_pinned, pinned, false);

alter table public.messages drop constraint if exists messages_type_check;
alter table public.messages add constraint messages_type_check check (
  type in (
    'text', 'image', 'video', 'audio', 'location', 'event', 'event_share',
    'announcement', 'mood', 'system', 'gif', 'file'
  )
);

drop policy if exists "Messages insert" on public.messages;
create policy "Messages insert"
  on public.messages for insert to authenticated
  with check (
    user_id = auth.uid()
    and family_id in (
      select family_id from public.family_members where user_id = auth.uid()
    )
  );

drop policy if exists "Messages update own" on public.messages;
create policy "Messages update own"
  on public.messages for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "Messages delete own" on public.messages;
create policy "Messages delete own"
  on public.messages for delete to authenticated
  using (user_id = auth.uid());

-- Reactions are changed atomically to avoid lost updates from two devices.
create or replace function public.toggle_message_reaction(
  p_message_id uuid,
  p_emoji text
) returns void as $$
declare
  v_reactions jsonb;
  v_users jsonb;
  v_user_id text := auth.uid()::text;
begin
  if auth.uid() is null or nullif(trim(p_emoji), '') is null then
    raise exception 'Geçersiz tepki';
  end if;

  select m.reactions into v_reactions
  from public.messages m
  where m.id = p_message_id
    and m.family_id in (
      select family_id from public.family_members where user_id = auth.uid()
    )
  for update;

  if not found then
    raise exception 'Mesaj bulunamadı veya erişim yetkisi yok';
  end if;

  v_reactions := coalesce(v_reactions, '{}'::jsonb);
  v_users := case
    when jsonb_typeof(v_reactions -> p_emoji) = 'array'
      then v_reactions -> p_emoji
    else '[]'::jsonb
  end;

  if v_users ? v_user_id then
    v_users := v_users - v_user_id;
  else
    v_users := v_users || jsonb_build_array(v_user_id);
  end if;

  if jsonb_array_length(v_users) = 0 then
    v_reactions := v_reactions - p_emoji;
  else
    v_reactions := jsonb_set(v_reactions, array[p_emoji], v_users, true);
  end if;

  update public.messages set reactions = v_reactions where id = p_message_id;
end;
$$ language plpgsql security definer set search_path = '';

create or replace function public.set_message_pinned(
  p_message_id uuid,
  p_pinned boolean
) returns void as $$
declare
  v_family_id uuid;
begin
  select m.family_id into v_family_id
  from public.messages m
  where m.id = p_message_id
    and m.family_id in (
      select family_id from public.family_members where user_id = auth.uid()
    );

  if v_family_id is null then
    raise exception 'Mesaj bulunamadı veya erişim yetkisi yok';
  end if;

  update public.messages
  set is_pinned = case when id = p_message_id then p_pinned else false end
  where family_id = v_family_id;
end;
$$ language plpgsql security definer set search_path = '';

revoke all on function public.toggle_message_reaction(uuid, text) from public;
revoke all on function public.set_message_pinned(uuid, boolean) from public;
grant execute on function public.toggle_message_reaction(uuid, text) to authenticated;
grant execute on function public.set_message_pinned(uuid, boolean) to authenticated;

-- 3. Private chat media. Paths are family_id/user_id/random-file-name.
insert into storage.buckets (id, name, public)
values ('chat-media', 'chat-media', false)
on conflict (id) do update set public = false;

drop policy if exists "Chat media family read" on storage.objects;
create policy "Chat media family read"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-media'
    and (storage.foldername(name))[1] in (
      select family_id::text from public.family_members where user_id = auth.uid()
    )
  );

drop policy if exists "Chat media own upload" on storage.objects;
create policy "Chat media own upload"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-media'
    and (storage.foldername(name))[2] = auth.uid()::text
    and (storage.foldername(name))[1] in (
      select family_id::text from public.family_members where user_id = auth.uid()
    )
  );

drop policy if exists "Chat media own delete" on storage.objects;
create policy "Chat media own delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'chat-media'
    and (storage.foldername(name))[2] = auth.uid()::text
    and (storage.foldername(name))[1] in (
      select family_id::text from public.family_members where user_id = auth.uid()
    )
  );

-- 4. Premium/admin fields can only be changed by trusted server roles.
alter table public.profiles add column if not exists subscription_provider text;
revoke update on table public.profiles from authenticated;
do $$
declare
  v_columns text;
begin
  select string_agg(format('%I', column_name), ', ' order by ordinal_position)
  into v_columns
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'profiles'
    and column_name <> all (array[
      'id', 'created_at', 'family_id', 'is_admin', 'is_premium',
      'subscription_tier', 'subscription_expires_at', 'subscription_provider',
      'premium_subscriptions', 'security_answer_1_hash', 'security_answer_2_hash'
    ]);

  if v_columns is not null then
    execute format(
      'grant update (%s) on table public.profiles to authenticated',
      v_columns
    );
  end if;
end $$;

create or replace function public.is_premium_user(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = p_user_id
      and (
        subscription_tier in ('premium', 'family') or is_premium = true
      )
      and (
        subscription_expires_at is null or subscription_expires_at > now()
      )
  );
$$;

create or replace function public.can_access_feature(
  p_user_id uuid,
  p_feature text
) returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user_id is distinct from auth.uid() then
    return false;
  end if;

  if p_feature in ('chat', 'calendar', 'tasks_basic', 'location_basic') then
    return true;
  end if;

  if p_feature in (
    'ai_assistant', 'advanced_analytics', 'unlimited_storage',
    'priority_support', 'custom_themes', 'export_data'
  ) then
    return public.is_premium_user(p_user_id);
  end if;

  return false;
end;
$$;
