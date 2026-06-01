-- 1. Enable the HTTP extension if not enabled
create extension if not exists "pg_net" with schema "extensions";

-- 2. Create the function to invoke our Edge Function
create or replace function public.invoke_notification_relay()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  service_role_key text := 'ضع_هنا_service_role_key_الخاص_بك';
begin
  -- Invoke the Edge Function asynchronously
  perform
    net.http_post(
      url := 'https://dsddwqdixsdhaspfafuy.supabase.co/functions/v1/notify-outbox-relay',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := '{}'
    );
  
  return new;
end;
$$;

-- 3. Create the trigger to fire on INSERT
drop trigger if exists tr_notify_outbox_inserted on public.notifications_outbox;
create trigger tr_notify_outbox_inserted
after insert on public.notifications_outbox
for each row
execute function public.invoke_notification_relay();

-- 4. Create the trigger to fire on update of status back to pending
drop trigger if exists tr_notify_outbox_updated on public.notifications_outbox;
create trigger tr_notify_outbox_updated
after update of status on public.notifications_outbox
for each row
when (new.status = 'pending' and old.status != 'pending')
execute function public.invoke_notification_relay();
