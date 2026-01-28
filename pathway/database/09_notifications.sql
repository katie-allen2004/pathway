-- notifications.

CREATE TABLE IF NOT EXISTS pathway.notifications (
  notification_id BIGSERIAL PRIMARY KEY,

  recipient_user_id BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  actor_user_id BIGINT REFERENCES pathway.users(user_id) ON DELETE SET NULL,

  -- example types: 'dm', 'new_review', 'venue_update'
  type TEXT NOT NULL,

  -- optional links to the thing the notification is about
  venue_id BIGINT REFERENCES pathway.venues(venue_id) ON DELETE CASCADE,
  review_id BIGINT REFERENCES pathway.venue_reviews(review_id) ON DELETE CASCADE,
  conversation_id BIGINT REFERENCES pathway.conversations(conversation_id) ON DELETE CASCADE,
  message_id BIGINT REFERENCES pathway.messages(message_id) ON DELETE CASCADE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at TIMESTAMPTZ
);
