-- accessibility tags and venue tag assignments.

CREATE TABLE IF NOT EXISTS pathway.accessibility_tags (
  tag_id BIGSERIAL PRIMARY KEY,
  tag_name TEXT NOT NULL UNIQUE
);

-- join table: venues <-> tags
CREATE TABLE IF NOT EXISTS pathway.venue_tags (
  venue_id BIGINT NOT NULL REFERENCES pathway.venues(venue_id) ON DELETE CASCADE,
  tag_id   BIGINT NOT NULL REFERENCES pathway.accessibility_tags(tag_id) ON DELETE CASCADE,
  PRIMARY KEY (venue_id, tag_id)
);

-- seed a few tags
INSERT INTO pathway.accessibility_tags (tag_name) VALUES
  ('Wheelchair Accessible'),
  ('Accessible Restroom'),
  ('Accessible Parking')
ON CONFLICT (tag_name) DO NOTHING;

-- create table for user accessibility tags
create table if not exists pathway.user_accessibility_tags (
  user_id bigint not null references pathway.users(user_id) on delete cascade,
  tag_id  bigint not null references pathway.accessibility_tags(tag_id) on delete cascade,
  primary key (user_id, tag_id)
);
