-- users can subscribe/follow other users and venues.

-- user follows another user
CREATE TABLE IF NOT EXISTS pathway.user_subscriptions (
  subscriber_user_id BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  target_user_id     BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (subscriber_user_id, target_user_id)
);

-- user subscribes to a venue
CREATE TABLE IF NOT EXISTS pathway.venue_subscriptions (
  user_id  BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  venue_id BIGINT NOT NULL REFERENCES pathway.venues(venue_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, venue_id)
);

create table if not exists pathway.friend_requests (
  request_id bigserial primary key,

  requester_user_id bigint not null references pathway.users(user_id) on delete cascade,
  target_user_id    bigint not null references pathway.users(user_id) on delete cascade,

  -- status (pending, accepted, declined)
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),

  created_at timestamptz not null default now(),
  responded_at timestamptz
);

-- prevent duplicates
create unique index if not exists ux_friend_requests_pair
  on pathway.friend_requests (requester_user_id, target_user_id);

create index if not exists idx_friend_requests_target_status
  on pathway.friend_requests (target_user_id, status);

-- once a friend request is accepted, add the friendship to the friends table and remove the friend request
create table if not exists pathway.friends (
  user_low_id  bigint not null references pathway.users(user_id) on delete cascade,
  user_high_id bigint not null references pathway.users(user_id) on delete cascade,

  created_at timestamptz not null default now(),

  primary key (user_low_id, user_high_id),
  check (user_low_id < user_high_id)
);

create index if not exists idx_friends_low on pathway.friends (user_low_id);
create index if not exists idx_friends_high on pathway.friends (user_high_id);

-- accept a friend request
create or replace function pathway.accept_friend_request(p_request_id bigint)
returns void
language plpgsql
security definer
as $$
declare
  req record;
  a bigint;
  b bigint;
begin
  -- get the request row
  select * into req
  from pathway.friend_requests
  where request_id = p_request_id;

  if req is null then
    raise exception 'Friend request not found';
  end if;

  -- update request status
  update pathway.friend_requests
  set status = 'accepted',
      responded_at = now()
  where request_id = p_request_id;

  -- store friendship in sorted order
  a := least(req.requester_user_id, req.target_user_id);
  b := greatest(req.requester_user_id, req.target_user_id);

  insert into pathway.friends (user_low_id, user_high_id)
  values (a, b)
  on conflict do nothing;
end;
$$;

-- decline a friend request
create or replace function pathway.decline_friend_request(p_request_id bigint)
returns void
language sql
security definer
as $$
  update pathway.friend_requests
  set status = 'declined',
      responded_at = now()
  where request_id = p_request_id;
$$;

grant execute on function pathway.accept_friend_request(bigint) to authenticated;
grant execute on function pathway.decline_friend_request(bigint) to authenticated;

-- make sure RLS is enabled
alter table pathway.friend_requests enable row level security;
alter table pathway.friends enable row level security;

-- users can see friend requests when they are requester or target
drop policy if exists "friend_requests read own" on pathway.friend_requests;
create policy "friend_requests read own"
on pathway.friend_requests
for select
using (
  requester_user_id = (
    select user_id from pathway.users where external_id = auth.uid()::text
  )
  or
  target_user_id = (
    select user_id from pathway.users where external_id = auth.uid()::text
  )
);

-- users can create outgoing requests
drop policy if exists "friend_requests insert own" on pathway.friend_requests;
create policy "friend_requests insert own"
on pathway.friend_requests
for insert
with check (
  requester_user_id = (
    select user_id from pathway.users where external_id = auth.uid()::text
  )
  and requester_user_id <> target_user_id
);

-- users can accept/decline a request only if they are the target
drop policy if exists "friend_requests update target only" on pathway.friend_requests;
create policy "friend_requests update target only"
on pathway.friend_requests
for update
using (
  target_user_id = (
    select user_id from pathway.users where external_id = auth.uid()::text
  )
);

-- user can only see friendships that include them
drop policy if exists "friends read own" on pathway.friends;
create policy "friends read own"
on pathway.friends
for select
using (
  user_low_id = (select user_id from pathway.users where external_id = auth.uid()::text)
  or
  user_high_id = (select user_id from pathway.users where external_id = auth.uid()::text)
);