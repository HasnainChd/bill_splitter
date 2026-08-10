-- Migration: Grant privileges on public.group_notifications to service_role
-- Fixes Postgres error 42501 (permission denied) when Edge Function queries group_notifications using service role key

grant all on table public.group_notifications to service_role, authenticated, postgres;
