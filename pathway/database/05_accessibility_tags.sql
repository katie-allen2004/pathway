-- tags describe accessibility features ("Wheelchair Accessible").

CREATE TABLE IF NOT EXISTS pathway.accessibility_tags (
  tag_id BIGSERIAL PRIMARY KEY,
  tag_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS pathway.venue_tags (
  venue_id BIGINT NOT NULL REFERENCES pathway.venues(venue_id) ON DELETE CASCADE,
  tag_id   BIGINT NOT NULL REFERENCES pathway.accessibility_tags(tag_id) ON DELETE CASCADE,
  PRIMARY KEY (venue_id, tag_id)
);
