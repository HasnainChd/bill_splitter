-- Create group_notifications table to persist group membership changes (joins, leaves)
create table if not exists public.group_notifications (
  id uuid default gen_random_uuid() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  event_type text not null, -- 'joined', 'left'
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.group_notifications enable row level security;

-- Policies for public.group_notifications
drop policy if exists "Users can view group_notifications for their groups" on public.group_notifications;
create policy "Users can view group_notifications for their groups" on public.group_notifications
  for select using (
    exists (
      select 1 from public.group_members
      where group_members.group_id = group_notifications.group_id
      and group_members.user_id = auth.uid()
    )
  );

drop policy if exists "Users can insert group_notifications for their groups" on public.group_notifications;
create policy "Users can insert group_notifications for their groups" on public.group_notifications
  for insert with check (
    exists (
      select 1 from public.group_members
      where group_members.group_id = group_notifications.group_id
      and group_members.user_id = auth.uid()
    )
  );

-- Enable Realtime for group_notifications
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'group_notifications'
  ) then
    alter publication supabase_realtime add table public.group_notifications;
  end if;
end $$;
