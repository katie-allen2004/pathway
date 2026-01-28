-- Reporting users and badges.

-- report a user
CREATE TABLE IF NOT EXISTS pathway.user_reports (
  report_id BIGSERIAL PRIMARY KEY,
  reporter_user_id BIGINT REFERENCES pathway.users(user_id) ON DELETE SET NULL,
  reported_user_id BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- badges list
CREATE TABLE IF NOT EXISTS pathway.badges (
  badge_id BIGSERIAL PRIMARY KEY,
  badge_name TEXT NOT NULL UNIQUE,
  description TEXT
);

-- which badges a user earned
CREATE TABLE IF NOT EXISTS pathway.user_badges (
  user_id BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  badge_id BIGINT NOT NULL REFERENCES pathway.badges(badge_id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, badge_id)
);
