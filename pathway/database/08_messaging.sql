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
