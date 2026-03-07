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

-- add an expiry time so messages auto delete
alter table pathway.messages
add column if not exists expires_at timestamptz;

-- set expiry for any old rows that don't have it yet
update pathway.messages
set expires_at = created_at + interval '7 days'
where expires_at is null;

-- auto set expires_at for new messages
create or replace function pathway.set_message_expiry()
returns trigger
language plpgsql
as $$
begin
  if new.expires_at is null then
    new.expires_at := new.created_at + interval '7 days';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_set_message_expiry on pathway.messages;

create trigger trg_set_message_expiry
before insert on pathway.messages
for each row
execute function pathway.set_message_expiry();