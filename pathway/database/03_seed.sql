-- starter data that depends ONLY on tables from 01.

INSERT INTO pathway.roles (role_name) VALUES
  ('user'),
  ('admin')
ON CONFLICT (role_name) DO NOTHING;
