-- Review Credibility Voting System (CLEAN VERSION)
-- Users can vote on reviews as helpful, outdated, or inaccurate
-- Uses UUID for user_id to match existing schema

-- Vote types enum
DO $$ BEGIN
  CREATE TYPE pathway.vote_type AS ENUM ('helpful', 'outdated', 'inaccurate');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Review votes table
CREATE TABLE IF NOT EXISTS pathway.review_votes (
  vote_id BIGSERIAL PRIMARY KEY,
  review_id BIGINT NOT NULL,
  user_id UUID NOT NULL,
  vote_type pathway.vote_type NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (review_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_review_votes_review_id ON pathway.review_votes(review_id);
CREATE INDEX IF NOT EXISTS idx_review_votes_user_id ON pathway.review_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_review_votes_type ON pathway.review_votes(vote_type);

-- Rate limiting table
CREATE TABLE IF NOT EXISTS pathway.vote_rate_limits (
  user_id UUID PRIMARY KEY,
  last_vote_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  vote_count_in_window INT NOT NULL DEFAULT 1
);

-- Vote counts view
CREATE OR REPLACE VIEW pathway.review_vote_counts AS
SELECT 
  r.review_id,
  COALESCE(SUM(CASE WHEN v.vote_type = 'helpful' THEN 1 ELSE 0 END), 0) AS helpful_count,
  COALESCE(SUM(CASE WHEN v.vote_type = 'outdated' THEN 1 ELSE 0 END), 0) AS outdated_count,
  COALESCE(SUM(CASE WHEN v.vote_type = 'inaccurate' THEN 1 ELSE 0 END), 0) AS inaccurate_count,
  COALESCE(COUNT(v.vote_id), 0) AS total_votes
FROM pathway.venue_reviews r
LEFT JOIN pathway.review_votes v ON r.review_id = v.review_id
GROUP BY r.review_id;

-- Flagged reviews view (for moderation)
CREATE OR REPLACE VIEW pathway.flagged_reviews AS
SELECT 
  r.review_id,
  r.venue_id,
  r.user_id,
  r.rating,
  r.review_text,
  r.created_at,
  vc.helpful_count,
  vc.outdated_count,
  vc.inaccurate_count,
  vc.total_votes,
  v.name AS venue_name,
  p.display_name AS author_name
FROM pathway.venue_reviews r
INNER JOIN pathway.review_vote_counts vc ON r.review_id = vc.review_id
LEFT JOIN pathway.venues v ON r.venue_id = v.venue_id
LEFT JOIN pathway.profiles p ON r.user_id = p.user_id
WHERE vc.outdated_count >= 3 OR vc.inaccurate_count >= 3
ORDER BY (vc.outdated_count + vc.inaccurate_count) DESC;

-- Rate limit check function (max 10 votes per minute)
CREATE OR REPLACE FUNCTION pathway.check_vote_rate_limit(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pathway, public
AS $$
DECLARE
  v_last_vote TIMESTAMPTZ;
  v_count INT;
  v_window_start TIMESTAMPTZ := now() - INTERVAL '1 minute';
BEGIN
  SELECT last_vote_at, vote_count_in_window
  INTO v_last_vote, v_count
  FROM pathway.vote_rate_limits
  WHERE user_id = p_user_id;
  
  IF v_last_vote IS NULL THEN
    INSERT INTO pathway.vote_rate_limits (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN TRUE;
  END IF;
  
  IF v_last_vote < v_window_start THEN
    UPDATE pathway.vote_rate_limits
    SET last_vote_at = now(), vote_count_in_window = 1
    WHERE user_id = p_user_id;
    RETURN TRUE;
  END IF;
  
  IF v_count >= 10 THEN
    RETURN FALSE;
  END IF;
  
  UPDATE pathway.vote_rate_limits
  SET last_vote_at = now(), vote_count_in_window = v_count + 1
  WHERE user_id = p_user_id;
  
  RETURN TRUE;
END;
$$;

-- Submit vote function
CREATE OR REPLACE FUNCTION pathway.submit_review_vote(
  p_review_id BIGINT,
  p_user_id UUID,
  p_vote_type pathway.vote_type
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pathway, public
AS $$
DECLARE
  v_review_author_id UUID;
  v_within_limit BOOLEAN;
  v_vote_id BIGINT;
BEGIN
  -- Check rate limit
  v_within_limit := pathway.check_vote_rate_limit(p_user_id);
  IF NOT v_within_limit THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'rate_limit_exceeded',
      'message', 'Too many votes. Please wait a moment.'
    );
  END IF;
  
  -- Check that user is not voting on their own review
  SELECT user_id INTO v_review_author_id
  FROM pathway.venue_reviews
  WHERE review_id = p_review_id;
  
  IF v_review_author_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'review_not_found',
      'message', 'Review not found.'
    );
  END IF;
  
  IF v_review_author_id = p_user_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'self_vote',
      'message', 'You cannot vote on your own review.'
    );
  END IF;
  
  -- Insert or update vote
  INSERT INTO pathway.review_votes (review_id, user_id, vote_type)
  VALUES (p_review_id, p_user_id, p_vote_type)
  ON CONFLICT (review_id, user_id)
  DO UPDATE SET 
    vote_type = p_vote_type,
    updated_at = now()
  RETURNING vote_id INTO v_vote_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'vote_id', v_vote_id,
    'message', 'Vote submitted successfully.'
  );
END;
$$;

-- Check if review is flagged
CREATE OR REPLACE FUNCTION pathway.is_review_flagged(p_review_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_outdated INT;
  v_inaccurate INT;
BEGIN
  SELECT outdated_count, inaccurate_count
  INTO v_outdated, v_inaccurate
  FROM pathway.review_vote_counts
  WHERE review_id = p_review_id;
  
  RETURN (v_outdated >= 3 OR v_inaccurate >= 3);
END;
$$;

-- Calculate weighted venue score
CREATE OR REPLACE FUNCTION pathway.calculate_venue_weighted_score(p_venue_id BIGINT)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_review RECORD;
  v_weighted_sum NUMERIC := 0;
  v_weight_sum NUMERIC := 0;
BEGIN
  FOR v_review IN
    SELECT r.rating, vc.helpful_count, vc.outdated_count, vc.inaccurate_count
    FROM pathway.venue_reviews r
    LEFT JOIN pathway.review_vote_counts vc ON r.review_id = vc.review_id
    WHERE r.venue_id = p_venue_id
  LOOP
    DECLARE
      v_weight NUMERIC;
      v_positive_bonus NUMERIC;
      v_negative_penalty NUMERIC;
    BEGIN
      v_positive_bonus := LEAST(v_review.helpful_count * 0.2, 2.0);
      v_negative_penalty := (v_review.outdated_count + v_review.inaccurate_count) * 0.3;
      v_weight := GREATEST(1.0 + v_positive_bonus - v_negative_penalty, 0.1);
      
      v_weighted_sum := v_weighted_sum + (v_review.rating * v_weight);
      v_weight_sum := v_weight_sum + v_weight;
    END;
  END LOOP;
  
  IF v_weight_sum = 0 THEN
    RETURN 0;
  END IF;
  
  RETURN ROUND(v_weighted_sum / v_weight_sum, 2);
END;
$$;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON pathway.review_votes TO authenticated;
GRANT USAGE ON SEQUENCE pathway.review_votes_vote_id_seq TO authenticated;
GRANT SELECT, INSERT, UPDATE ON pathway.vote_rate_limits TO authenticated;
GRANT SELECT ON pathway.review_vote_counts TO authenticated;
GRANT SELECT ON pathway.flagged_reviews TO authenticated;
GRANT EXECUTE ON FUNCTION pathway.submit_review_vote(BIGINT, UUID, pathway.vote_type) TO authenticated;
GRANT EXECUTE ON FUNCTION pathway.check_vote_rate_limit(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION pathway.calculate_venue_weighted_score(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION pathway.is_review_flagged(BIGINT) TO authenticated;
