# Pathway Database (Azure PostgreSQL)

This folder is the SQL scripts for creating the Pathway database schema and seed data.

## Files
Run scripts in this order:

1. `01_schema.sql` — creates schema + tables  
2. `02_constraints_indexes.sql` — indexes / constraints  
3. `03_seed.sql` — seed data (ex: roles)

### Create the database
Open a **New Query** connected to the `postgres` database and run:

```sql
CREATE DATABASE pathway;