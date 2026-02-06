--create the schema and the basic user tables.

CREATE SCHEMA IF NOT EXISTS pathway;

-- Users table
-- external_id is a string you can store from
CREATE TABLE IF NOT EXISTS pathway.users (
  user_id      BIGSERIAL PRIMARY KEY,
  external_id  TEXT NOT NULL UNIQUE,
  email        TEXT UNIQUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Roles table
CREATE TABLE IF NOT EXISTS pathway.roles (
  role_id    BIGSERIAL PRIMARY KEY,
  role_name  TEXT NOT NULL UNIQUE
);

-- users roles
CREATE TABLE IF NOT EXISTS pathway.user_roles (
  user_id  BIGINT NOT NULL REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  role_id  BIGINT NOT NULL REFERENCES pathway.roles(role_id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- Profiles table
CREATE TABLE IF NOT EXISTS pathway.profiles (
  profile_id    BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL UNIQUE REFERENCES pathway.users(user_id) ON DELETE CASCADE,
  display_name  TEXT,
  bio           TEXT,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
