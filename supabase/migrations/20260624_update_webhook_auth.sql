-- Update webhook to include auth.uid()
create or replace function public.handle_notification_webhook()
returns trigger language plpgsql security definer as $$
declare
  payload jsonb;
  webhook_url text;
  current_user_id uuid;
begin
  webhook_url := 'https://muqtqecqeztidvgafqsy.supabase.co/functions/v1/send-notification';
  
  -- get the current user ID making the request
  current_user_id := auth.uid();
  
  payload := jsonb_build_object(
    'table', tg_table_name,
    'operation', tg_op,
    'new_record', to_jsonb(new),
    'old_record', to_jsonb(old),
    'auth_user_id', current_user_id
  );

  perform net.http_post(
    url := webhook_url,
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := payload
  );

  return new;
end;
$$;
