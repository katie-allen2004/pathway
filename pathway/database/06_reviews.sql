-- reviews for venues.

CREATE TABLE IF NOT EXISTS pathway.venue_reviews (
  review_id BIGSERIAL PRIMARY KEY,

  venue_id BIGINT NOT NULL REFERENCES pathway.venues(venue_id) ON DELETE CASCADE,
  user_id  BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,

  -- rating is 1 to 5
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),

  review_text TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- starting with one review per user per venue
  UNIQUE (venue_id, user_id)
);

-- photos for a review (url)
CREATE TABLE IF NOT EXISTS pathway.review_photos (
  photo_id BIGSERIAL PRIMARY KEY,
  review_id BIGINT NOT NULL REFERENCES pathway.venue_reviews(review_id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- tags on reviews
CREATE TABLE IF NOT EXISTS pathway.review_tags (
  review_id BIGINT NOT NULL REFERENCES pathway.venue_reviews(review_id) ON DELETE CASCADE,
  tag_id BIGINT NOT NULL REFERENCES pathway.accessibility_tags(tag_id) ON DELETE CASCADE,
  PRIMARY KEY (review_id, tag_id)
);

-- -------------------------------------------------------
-- Row Level Security
-- -------------------------------------------------------

ALTER TABLE pathway.venue_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE pathway.review_photos  ENABLE ROW LEVEL SECURITY;
ALTER TABLE pathway.review_tags    ENABLE ROW LEVEL SECURITY;

-- venue_reviews policies
-- venue_reviews.user_id stores the Supabase auth UUID (uuid type), not a pathway.users integer FK
CREATE POLICY "venue_reviews_select_all"
  ON pathway.venue_reviews FOR SELECT TO authenticated USING (true);

CREATE POLICY "venue_reviews_insert_own"
  ON pathway.venue_reviews FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "venue_reviews_update_own"
  ON pathway.venue_reviews FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "venue_reviews_delete_own"
  ON pathway.venue_reviews FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- review_photos policies
CREATE POLICY "review_photos_select_all"
  ON pathway.review_photos FOR SELECT TO authenticated USING (true);

CREATE POLICY "review_photos_insert_own"
  ON pathway.review_photos FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM pathway.venue_reviews vr
      WHERE vr.review_id = review_photos.review_id
        AND vr.user_id = auth.uid()
    )
  );

CREATE POLICY "review_photos_delete_own"
  ON pathway.review_photos FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM pathway.venue_reviews vr
      WHERE vr.review_id = review_photos.review_id
        AND vr.user_id = auth.uid()
    )
  );

-- review_tags policies
CREATE POLICY "review_tags_select_all"
  ON pathway.review_tags FOR SELECT TO authenticated USING (true);

CREATE POLICY "review_tags_insert_own"
  ON pathway.review_tags FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM pathway.venue_reviews vr
      WHERE vr.review_id = review_tags.review_id
        AND vr.user_id = auth.uid()
    )
  );

CREATE POLICY "review_tags_delete_own"
  ON pathway.review_tags FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM pathway.venue_reviews vr
      WHERE vr.review_id = review_tags.review_id
        AND vr.user_id = auth.uid()
    )
  );