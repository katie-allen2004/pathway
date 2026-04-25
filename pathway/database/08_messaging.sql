-- messaging system.

-- a conversation can be a DM or a group chat.
CREATE TABLE IF NOT EXISTS pathway.conversations (
  conversation_id BIGSERIAL PRIMARY KEY,
  is_group BOOLEAN NOT NULL DEFAULT false,
  title TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- users inside a conversation
CREATE TABLE IF NOT EXISTS pathway.conversation_members (
  conversation_id BIGINT NOT NULL REFERENCES pathway.conversations(conversation_id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (conversation_id, user_id)
);

-- messages inside a conversation
CREATE TABLE IF NOT EXISTS pathway.messages (
  message_id BIGSERIAL PRIMARY KEY,
  conversation_id BIGINT NOT NULL REFERENCES pathway.conversations(conversation_id) ON DELETE CASCADE,
  sender_user_id BIGINT REFERENCES pathway.users(user_id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- conversations
alter table pathway.conversations enable row level security;

-- allow authenticated users to create conversations
drop policy if exists "conversations insert authenticated" on pathway.conversations;
create policy "conversations insert authenticated"
on pathway.conversations
for insert
to authenticated
with check (true);

-- allow users to read conversations they are a member of
drop policy if exists "conversations read own" on pathway.conversations;
create policy "conversations read own"
on pathway.conversations
for select
to authenticated
using (
  conversation_id in (
    select cm.conversation_id
    from pathway.conversation_members cm
    where cm.user_id = (
      select u.user_id
      from pathway.users u
      where u.external_id = auth.uid()::text
    )
  )
);

-- conversation members

alter table pathway.conversation_members enable row level security;

drop policy if exists "conversation_members read own conversations" on pathway.conversation_members;
drop policy if exists "conversation_members insert authenticated" on pathway.conversation_members;

-- simple read policy so the app can inspect memberships
create policy "conversation_members read authenticated"
on pathway.conversation_members
for select
to authenticated
using (true);

-- allow authenticated users to add members when creating a dm/group
create policy "conversation_members insert authenticated"
on pathway.conversation_members
for insert
to authenticated
with check (true);


-- messaging
alter table pathway.messages enable row level security;

-- allow users to read messages in conversations they are a member of
drop policy if exists "messages read own conversations" on pathway.messages;
create policy "messages read own conversations"
on pathway.messages
for select
to authenticated
using (
  conversation_id in (
    select cm.conversation_id
    from pathway.conversation_members cm
    where cm.user_id = (
      select u.user_id
      from pathway.users u
      where u.external_id = auth.uid()::text
    )
  )
);

-- allow users to send messages as themselves in conversations they are a member of
drop policy if exists "messages insert own" on pathway.messages;
create policy "messages insert own"
on pathway.messages
for insert
to authenticated
with check (
  sender_user_id = (
    select u.user_id
    from pathway.users u
    where u.external_id = auth.uid()::text
  )
  and conversation_id in (
    select cm.conversation_id
    from pathway.conversation_members cm
    where cm.user_id = (
      select u.user_id
      from pathway.users u
      where u.external_id = auth.uid()::text
    )
  )
);