--notifications.

-- turn on RLS though SQL just to be sure its on
alter table pathway.notifications enable row level security;

-- user can only see notifications that belong to them
drop policy if exists "notifications read own" on pathway.notifications;
create policy "notifications read own"
on pathway.notifications
for select
using (
  recipient_user_id = (
    -- find the current user's pathway.users row by matching auth.uid()
    select u.user_id
    from pathway.users u
    where u.external_id = auth.uid()::text
  )
);

-- user can only update their own notifications
drop policy if exists "notifications update own" on pathway.notifications;
create policy "notifications update own"
on pathway.notifications
for update
using (
  recipient_user_id = (
    select u.user_id
    from pathway.users u
    where u.external_id = auth.uid()::text
  )
)
with check (
  recipient_user_id = (
    select u.user_id
    from pathway.users u
    where u.external_id = auth.uid()::text
  )
);

-- user can delete only their own notifications
drop policy if exists "notifications delete own" on pathway.notifications;
create policy "notifications delete own"
on pathway.notifications
for delete
using (
  recipient_user_id = (
    select u.user_id
    from pathway.users u
    where u.external_id = auth.uid()::text
  )
);

-- create notifications from the app
create or replace function pathway.create_notification(
  p_recipient_user_id bigint,
  p_type text,
  p_actor_user_id bigint default null,
  p_venue_id bigint default null,
  p_review_id bigint default null,
  p_conversation_id bigint default null,
  p_message_id bigint default null
)
returns bigint
language plpgsql
security definer
as $$
declare
  new_id bigint;
begin
  -- insert one notification row
  insert into pathway.notifications (
    recipient_user_id,
    actor_user_id,
    type,
    venue_id,
    review_id,
    conversation_id,
    message_id
  )
  values (
    p_recipient_user_id,
    p_actor_user_id,
    p_type,
    p_venue_id,
    p_review_id,
    p_conversation_id,
    p_message_id
  )
  returning notification_id into new_id;

  -- return the new notification id to the caller
  return new_id;
end;
$$;

-- allow users to call this function
grant execute on function pathway.create_notification(
  bigint, text, bigint, bigint, bigint, bigint, bigint
) to authenticated;

-- notify everyone in chat when a new message is sent (excluding the sender)
create or replace function pathway.notify_on_new_message()
returns trigger
language plpgsql
security definer
as $$
begin
  -- notifications for all conversation members except the sender
  insert into pathway.notifications (
    recipient_user_id,
    actor_user_id,
    type,
    conversation_id,
    message_id
  )
  select
    cm.user_id as recipient_user_id,
    new.sender_user_id as actor_user_id,
    'dm' as type,
    new.conversation_id,
    new.message_id
  from pathway.conversation_members cm
  where cm.conversation_id = new.conversation_id
    and cm.user_id <> new.sender_user_id;

  return new;
end;
$$;

-- drop then create trigger to avoid duplicates if this file is run multiple times
drop trigger if exists trg_notify_on_new_message on pathway.messages;

create trigger trg_notify_on_new_message
after insert on pathway.messages
for each row
execute function pathway.notify_on_new_message();

-- when someone writes a new review, notify their followers
create or replace function pathway.notify_followers_on_new_review()
returns trigger
language plpgsql
security definer
as $$
begin
  -- one notification row per follower
  insert into pathway.notifications (
    recipient_user_id,
    actor_user_id,
    type,
    venue_id,
    review_id
  )
  select
    us.subscriber_user_id,
    new.user_id,
    'user_post',
    new.venue_id,
    new.review_id
  from pathway.user_subscriptions us
  where us.target_user_id = new.user_id
    and us.subscriber_user_id <> new.user_id;

  return new;
end;
$$;

-- run this function after a review is inserted
drop trigger if exists trg_notify_followers_on_new_review on pathway.venue_reviews;

create trigger trg_notify_followers_on_new_review
after insert on pathway.venue_reviews
for each row
execute function pathway.notify_followers_on_new_review();

-- notify venue subscribers when a new review is posted for that venue
create or replace function pathway.notify_venue_subscribers_on_new_review()
returns trigger
language plpgsql
security definer
as $$
begin
  -- one notification row per venue subscriber
  insert into pathway.notifications (
    recipient_user_id,
    actor_user_id,
    type,
    venue_id,
    review_id
  )
  select
    vs.user_id,
    new.user_id,
    'venue_post',
    new.venue_id,
    new.review_id
  from pathway.venue_subscriptions vs
  where vs.venue_id = new.venue_id
    and vs.user_id <> new.user_id;

  return new;
end;
$$;

-- run this function after a review is inserted in a venue
drop trigger if exists trg_notify_venue_subscribers_on_new_review on pathway.venue_reviews;

create trigger trg_notify_venue_subscribers_on_new_review
after insert on pathway.venue_reviews
for each row
execute function pathway.notify_venue_subscribers_on_new_review();

-- convert UUID to Bigint to avoid errors for testing
create or replace function pathway.notify_followers_on_new_review()
returns trigger
language plpgsql
security definer
as $$
declare
  actor_pathway_user_id bigint;
begin
  -- convert new.user_id to pathway.users.user_id
  select u.user_id
  into actor_pathway_user_id
  from pathway.users u
  where u.external_id = new.user_id::text;

  if actor_pathway_user_id is null then
    return new;
  end if;

  -- notify everyone who follows this user using new translation
  insert into pathway.notifications (
    recipient_user_id,
    actor_user_id,
    type,
    venue_id,
    review_id
  )
  select
    us.subscriber_user_id,
    actor_pathway_user_id,
    'user_post',
    new.venue_id,
    new.review_id
  from pathway.user_subscriptions us
  where us.target_user_id = actor_pathway_user_id
    and us.subscriber_user_id <> actor_pathway_user_id;

  return new;
end;
$$;

drop trigger if exists trg_notify_followers_on_new_review on pathway.venue_reviews;

create trigger trg_notify_followers_on_new_review
after insert on pathway.venue_reviews
for each row
execute function pathway.notify_followers_on_new_review();

-- do the same translation for venues
create or replace function pathway.notify_venue_subscribers_on_new_review()
returns trigger
language plpgsql
security definer
as $$
declare
  actor_pathway_user_id bigint;
begin
  select u.user_id
  into actor_pathway_user_id
  from pathway.users u
  where u.external_id = new.user_id::text;

  if actor_pathway_user_id is null then
    return new;
  end if;

  -- notify all users subscribed to this venue
  insert into pathway.notifications (
    recipient_user_id,
    actor_user_id,
    type,
    venue_id,
    review_id
  )
  select
    vs.user_id,
    actor_pathway_user_id,
    'venue_post',
    new.venue_id,
    new.review_id
  from pathway.venue_subscriptions vs
  where vs.venue_id = new.venue_id
    and vs.user_id <> actor_pathway_user_id;

  return new;
end;
$$;

drop trigger if exists trg_notify_venue_subscribers_on_new_review on pathway.venue_reviews;

create trigger trg_notify_venue_subscribers_on_new_review
after insert on pathway.venue_reviews
for each row
execute function pathway.notify_venue_subscribers_on_new_review();

-- enable realtime notifications in supabase
alter table pathway.notifications replica identity full;
alter publication supabase_realtime add table pathway.notifications;