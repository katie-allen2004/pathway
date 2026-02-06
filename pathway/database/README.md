# Pathway Database (PostgreSQL)

This folder contains the SQL scripts for creating the Pathway database structure and starter seed data. They work on Supabase

---

## Files (run in this order)

1. `01_schema.sql` — creates the `pathway` schema + core tables (users, roles, profiles)
2. `02_constraints_indexes.sql` — basic indexes
3. `03_seed.sql` — seed data for roles
4. `04_venues.sql` — venues table
5. `05_accessibility_tags.sql` — accessibility tags + venue_tags (includes starter tag seeds)
6. `06_reviews.sql` — reviews + review_photos + review_tags
7. `07_subscriptions.sql` — user_subscriptions + venue_subscriptions
8. `08_messaging.sql` — conversations + members + messages
9. `09_notifications.sql` — notifications table
10. `10_reporting_badges.sql` — user_reports + badges + user_badges (includes starter badge seeds)

---

## How to run in Supabase

1. Go to your Supabase project dashboard
2. Open **SQL Editor**
3. Click **New query**
4. Copy/paste each file **one at a time** in the order listed above and click **Run**
