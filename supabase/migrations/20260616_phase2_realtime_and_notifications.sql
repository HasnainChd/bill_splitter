-- Phase 2 SQL Migration: Realtime Sync, Schema Cleanup, and FCM Webhooks

-- 1. Enable Realtime on core tables
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'groups'
  ) then
    alter publication supabase_realtime add table public.groups;
  end if;
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'expenses'
  ) then
    alter publication supabase_realtime add table public.expenses;
  end if;
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'group_members'
  ) then
    alter publication supabase_realtime add table public.group_members;
  end if;
end $$;

-- 2. Schema Cleanup: Add icon metadata columns to groups table
alter table public.groups 
add column if not exists icon_code_point integer,
add column if not exists icon_font_family text;

-- 3. Data Migration: Extract existing icon tags from group names
update public.groups
set 
  icon_code_point = substring(name from '\[icon:(\d+)\]')::integer,
  icon_font_family = 'MaterialIcons',
  name = regexp_replace(name, '\s*\[icon:\d+\]\s*$', '')
where name ~ '\[icon:\d+\]';

-- 4. Create User Tokens table for FCM Registration
create table if not exists public.user_tokens (
  user_id uuid references auth.users(id) on delete cascade,
  fcm_token text not null,
  device_id text not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (user_id, device_id)
);

-- Enable RLS and add policies
alter table public.user_tokens enable row level security;

create policy "Users can manage their own tokens" on public.user_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 5. Webhook triggers for notifying Edge Functions on database updates
create extension if not exists pg_net with schema extensions;

create or replace function public.handle_notification_webhook()
returns trigger language plpgsql security definer as $$
declare
  payload jsonb;
  webhook_url text;
begin
  webhook_url := 'https://muqtqecqeztidvgafqsy.supabase.co/functions/v1/send-notification';
  
  payload := jsonb_build_object(
    'table', tg_table_name,
    'operation', tg_op,
    'new_record', to_jsonb(new),
    'old_record', to_jsonb(old)
  );

  perform net.http_post(
    url := webhook_url,
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := payload
  );

  return new;
end;
$$;

-- Attach triggers to public.expenses
drop trigger if exists on_expense_change_trigger on public.expenses;
create trigger on_expense_change_trigger
after insert or update or delete on public.expenses
for each row execute function public.handle_notification_webhook();

-- Attach triggers to public.group_members
drop trigger if exists on_group_member_change_trigger on public.group_members;
create trigger on_group_member_change_trigger
after insert or delete on public.group_members
for each row execute function public.handle_notification_webhook();
