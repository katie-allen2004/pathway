-- indexes to speed up common lookups

CREATE INDEX IF NOT EXISTS idx_users_email ON pathway.users(email);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON pathway.user_roles(role_id);
