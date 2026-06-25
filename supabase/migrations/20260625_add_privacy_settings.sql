-- Add privacy settings columns to public.users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS allow_invites TEXT DEFAULT 'Everyone',
ADD COLUMN IF NOT EXISTS share_analytics BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS read_receipts BOOLEAN DEFAULT true;

-- Enable Realtime for users table
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'users'
  ) then
    alter publication supabase_realtime add table public.users;
  end if;
end $$;
