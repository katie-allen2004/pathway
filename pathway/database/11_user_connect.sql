-- sets up permissions so users can only access their own data

drop view if exists pathway.me;

create view pathway.me as
select
  u.user_id,
  u.external_id,
  u.email,
  p.display_name,
  p.bio,
  p.avatar_url,
  p.updated_at
from pathway.users u
left join pathway.profiles p on p.user_id = u.user_id
where u.external_id = auth.uid()::text;
