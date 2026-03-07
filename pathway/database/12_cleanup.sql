-- deletes messages older than 7 days

create extension if not exists pg_cron;

create or replace function pathway.cleanup_old_messages()
returns void
language plpgsql
security definer
as $$
begin
  delete from pathway.messages
  where created_at < now() - interval '7 days';
end;
$$;

select cron.schedule(
  'weekly_message_cleanup',
  '0 3 * * 0',
  $$select pathway.cleanup_old_messages();$$
);