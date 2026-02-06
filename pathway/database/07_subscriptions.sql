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
