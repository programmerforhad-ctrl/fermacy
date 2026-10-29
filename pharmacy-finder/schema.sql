-- Supabase > SQL Editor e eta paste kore Run koro
create table if not exists medicines (
  id bigint generated always as identity primary key,
  name_en text not null,
  name_bn text,
  shelf_no text not null,
  price numeric,
  uses text,
  created_at timestamptz default now()
);
alter table medicines enable row level security;
create policy "anyone can read" on medicines for select using (true);
create policy "admin can write" on medicines for all to authenticated using (true) with check (true);

-- ===== Admin panel er extra table / storage =====
create table if not exists settings (id int primary key, title text, subtitle text);
alter table settings enable row level security;
create policy "read settings" on settings for select using (true);
create policy "admin settings" on settings for all to authenticated using (true) with check (true);

create table if not exists prescriptions (
  id bigint generated always as identity primary key,
  path text not null, found text[], missing text[],
  created_at timestamptz default now()
);
alter table prescriptions enable row level security;
create policy "anyone log scan" on prescriptions for insert to anon, authenticated with check (true);
create policy "admin read rx" on prescriptions for select to authenticated using (true);
create policy "admin delete rx" on prescriptions for delete to authenticated using (true);

-- Storage bucket "1" private hote hobe (Public bondho rakho)
create policy "anyone upload rx" on storage.objects for insert to anon, authenticated with check (bucket_id = '1');
create policy "admin read rx img" on storage.objects for select to authenticated using (bucket_id = '1');
create policy "admin delete rx img" on storage.objects for delete to authenticated using (bucket_id = '1');
