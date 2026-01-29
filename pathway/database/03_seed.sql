-- starter accessibility tags
INSERT INTO pathway.accessibility_tags (tag_name) VALUES
  ('Wheelchair Accessible'),
  ('Accessible Restroom'),
  ('Accessible Parking')
ON CONFLICT (tag_name) DO NOTHING;

-- starter badges
INSERT INTO pathway.badges (badge_name, description) VALUES
  ('First Review', 'Wrote your first review'),
  ('Explorer', 'Reviewed multiple venues')
ON CONFLICT (badge_name) DO NOTHING;
