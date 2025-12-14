CREATE SCHEMA IF NOT EXISTS pathway;

CREATE TABLE IF NOT EXISTS pathway.users (
  user_id      BIGSERIAL PRIMARY KEY,
  external_id  TEXT NOT NULL UNIQUE,
  email        TEXT UNIQUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pathway.roles (
  role_id    BIGSERIAL PRIMARY KEY,
  role_name  TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS pathway.user_roles (
  user_id  BIGINT NOT NULL,
  role_id  BIGINT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_roles_user
    FOREIGN KEY (user_id) REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_user_roles_role
    FOREIGN KEY (role_id) REFERENCES pathway.roles(role_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS pathway.profiles (
  profile_id    BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL UNIQUE,
  display_name  TEXT,
  bio           TEXT,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT fk_profiles_user
    FOREIGN KEY (user_id) REFERENCES pathway.users(user_id) ON DELETE CASCADE
);
