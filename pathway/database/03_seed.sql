INSERT INTO pathway.roles (role_name)
VALUES ('user'), ('admin')
ON CONFLICT (role_name) DO NOTHING;
