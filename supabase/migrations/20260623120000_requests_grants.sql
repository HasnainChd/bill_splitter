-- Phase 3 SQL Migration Fix: Grant Privileges
-- Grants explicit permissions on the requests table to the authenticated role.

GRANT ALL ON public.requests TO authenticated;
GRANT ALL ON public.requests TO anon;
GRANT ALL ON public.requests TO service_role;
