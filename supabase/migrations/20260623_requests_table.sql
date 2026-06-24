-- Phase 3 SQL Migration: Requests Table
-- Creates the requests table to track settlement requests.

create table if not exists public.requests (
  id uuid default gen_random_uuid() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  status text default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS and add policies
alter table public.requests enable row level security;

-- Users can view requests for groups they are members of
create policy "Users can view requests for their groups" on public.requests
  for select using (
    exists (
      select 1 from public.group_members
      where group_members.group_id = requests.group_id
      and group_members.user_id = auth.uid()
    )
  );

-- Users can insert requests for groups they are members of
create policy "Users can insert requests for their groups" on public.requests
  for insert with check (
    exists (
      select 1 from public.group_members
      where group_members.group_id = requests.group_id
      and group_members.user_id = auth.uid()
    )
  );

-- Enable Realtime for the requests table
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'requests'
  ) then
    alter publication supabase_realtime add table public.requests;
  end if;
end $$;

-- Attach trigger to public.requests for webhook notification
drop trigger if exists on_request_change_trigger on public.requests;
create trigger on_request_change_trigger
after insert on public.requests
for each row execute function public.handle_notification_webhook();
