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

-- photos for a review (store the URL for now)
CREATE TABLE IF NOT EXISTS pathway.review_photos (
  photo_id BIGSERIAL PRIMARY KEY,
  review_id BIGINT NOT NULL REFERENCES pathway.venue_reviews(review_id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
