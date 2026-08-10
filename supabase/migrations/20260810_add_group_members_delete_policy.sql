-- Migration: Add RLS DELETE policy for public.group_members
-- Allows users to remove themselves (leave) and group creators to remove members.

drop policy if exists "Users can leave or creator can remove members" on public.group_members;

create policy "Users can leave or creator can remove members"
on public.group_members
for delete
using (
  auth.uid() = user_id
  or exists (
    select 1 from public.groups
    where groups.id = group_members.group_id
    and groups.created_by = auth.uid()
  )
);
