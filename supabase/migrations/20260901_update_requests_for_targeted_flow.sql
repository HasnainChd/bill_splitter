-- Migration: Extend public.requests to support targeted requests
-- Adds target_user_id, amount, currency, note, responded_at, and status check constraint.
-- Updates RLS policies to allow targeted insertions, updates (status only), and group visibility.

-- 1. Add new columns
alter table public.requests
  add column if not exists target_user_id uuid references auth.users(id) on delete cascade,
  add column if not exists amount numeric,
  add column if not exists currency text,
  add column if not exists note text,
  add column if not exists responded_at timestamp with time zone;

-- 2. Add status check constraint
alter table public.requests
  drop constraint if exists requests_status_check;

alter table public.requests
  add constraint requests_status_check
  check (status in ('pending', 'accepted', 'declined', 'paid', 'cancelled'));

-- 3. Add performance indexes
create index if not exists idx_requests_target_user_id on public.requests(target_user_id);
create index if not exists idx_requests_group_id on public.requests(group_id);
create index if not exists idx_requests_user_id on public.requests(user_id);

-- 4. Enforce field immutability on UPDATE (Only status & responded_at can be updated)
create or replace function public.enforce_request_update_restrictions()
returns trigger as $$
begin
  if (NEW.id IS DISTINCT FROM OLD.id) OR
     (NEW.group_id IS DISTINCT FROM OLD.group_id) OR
     (NEW.user_id IS DISTINCT FROM OLD.user_id) OR
     (NEW.target_user_id IS DISTINCT FROM OLD.target_user_id) OR
     (NEW.amount IS DISTINCT FROM OLD.amount) OR
     (NEW.currency IS DISTINCT FROM OLD.currency) OR
     (NEW.note IS DISTINCT FROM OLD.note) OR
     (NEW.created_at IS DISTINCT FROM OLD.created_at) then
    raise exception 'Only status and responded_at columns can be modified on request updates.';
  end if;

  -- Automatically update responded_at if status changes and responded_at is not explicitly provided
  if (NEW.status IS DISTINCT FROM OLD.status) and (NEW.responded_at IS NULL or NEW.responded_at IS NOT DISTINCT FROM OLD.responded_at) then
    NEW.responded_at := timezone('utc'::text, now());
  end if;

  return NEW;
end;
$$ language plpgsql;

drop trigger if exists trg_enforce_request_update_restrictions on public.requests;

create trigger trg_enforce_request_update_restrictions
  before update on public.requests
  for each row
  execute function public.enforce_request_update_restrictions();

-- 5. RLS Policies

-- SELECT Policy: Group members can view requests for their groups, and recipients can view targeted requests
drop policy if exists "Users can view requests for their groups" on public.requests;

create policy "Users can view requests for their groups" on public.requests
  for select using (
    user_id = auth.uid()
    or target_user_id = auth.uid()
    or exists (
      select 1 from public.group_members
      where group_members.group_id = requests.group_id
      and group_members.user_id = auth.uid()
    )
  );

-- INSERT Policy: Group members can insert requests for their groups (generic or targeted to a group member)
drop policy if exists "Users can insert requests for their groups" on public.requests;

create policy "Users can insert requests for their groups" on public.requests
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.group_members gm
      where gm.group_id = requests.group_id
      and gm.user_id = auth.uid()
    )
    and (
      target_user_id is null
      or exists (
        select 1 from public.group_members gm_target
        where gm_target.group_id = requests.group_id
        and gm_target.user_id = requests.target_user_id
      )
    )
  );

-- UPDATE Policy: Target recipients or requesters in the group can update status (e.g. accept/decline/cancel)
drop policy if exists "Users can update request status" on public.requests;

create policy "Users can update request status" on public.requests
  for update using (
    (target_user_id = auth.uid() or user_id = auth.uid())
    and exists (
      select 1 from public.group_members
      where group_members.group_id = requests.group_id
      and group_members.user_id = auth.uid()
    )
  )
  with check (
    (target_user_id = auth.uid() or user_id = auth.uid())
  );
