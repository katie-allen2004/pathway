-- stores venues that users can view and review.

CREATE TABLE IF NOT EXISTS pathway.venues (
  venue_id BIGSERIAL PRIMARY KEY,

  name TEXT NOT NULL,
  description TEXT,

  -- basic address info
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,

  -- optional map coordinates
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,

  -- who created the venue
  created_by_user_id BIGINT REFERENCES pathway.users(user_id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- indexes
CREATE INDEX IF NOT EXISTS idx_venues_city ON pathway.venues(city);
CREATE INDEX IF NOT EXISTS idx_venues_state ON pathway.venues(state);


--2 Creating the saved venues table(favorite) This is me 
CREATE TABLE IF NOT EXISTS pathway.saved_venues (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  venue_id BIGINT REFERENCES pathway.venues(venue_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, venue_id) -- This will help with saving/favoriting the same venue twice
);

--indexes for perfomance 
CREATE INDEX IF NOT EXISTS idx_venues_city ON pathway.venues(city);
CREATE INDEX IF NOT EXISTS idx_venues_state ON pathway.venues(state);