-- schema.sql, update.sql er PORE eta run koro
alter table medicines
  add column if not exists company text,
  add column if not exists generic text,
  add column if not exists strength text,
  add column if not exists form text,
  add column if not exists price_unit text,
  add column if not exists side_effects text;

create table if not exists shelves (name text primary key, created_at timestamptz default now());
alter table shelves enable row level security;
create policy "anyone read shelves" on shelves for select using (true);
create policy "staff write shelves" on shelves for all to authenticated using (is_staff()) with check (is_staff());
insert into shelves(name) select distinct shelf_no from medicines on conflict do nothing;
