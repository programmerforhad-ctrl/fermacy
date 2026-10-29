-- schema.sql er PORE eta run koro (Supabase > SQL Editor)
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  email text, is_owner boolean default false, approved boolean default false,
  created_at timestamptz default now()
);
alter table profiles enable row level security;

create or replace function is_staff() returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from profiles where id=auth.uid() and approved) $$;
create or replace function is_owner() returns boolean language sql security definer stable set search_path=public as
$$ select exists(select 1 from profiles where id=auth.uid() and approved and is_owner) $$;

-- prothom je account khulbe se-i Owner (auto approved). Pore jara khulbe tara Owner approve na korle kaj korte parbe na.
create or replace function handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare first_user boolean;
begin
  select not exists(select 1 from profiles where is_owner) into first_user;
  insert into profiles(id,email,is_owner,approved) values(new.id,new.email,first_user,first_user);
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

-- age jei user banano hoyeche tader profile
insert into profiles(id,email) select id,email from auth.users on conflict do nothing;
update profiles set is_owner=true, approved=true
 where id=(select id from auth.users order by created_at limit 1) and not exists(select 1 from profiles where is_owner);

create policy "see own or all if owner" on profiles for select to authenticated using (id=auth.uid() or is_owner());
create policy "owner updates" on profiles for update to authenticated using (is_owner()) with check (is_owner());
create policy "owner deletes" on profiles for delete to authenticated using (is_owner());

-- write access shudhu approved staff er
drop policy if exists "admin can write" on medicines;
create policy "staff write" on medicines for all to authenticated using (is_staff()) with check (is_staff());
drop policy if exists "admin settings" on settings;
create policy "staff settings" on settings for all to authenticated using (is_staff()) with check (is_staff());
drop policy if exists "admin read rx" on prescriptions;
drop policy if exists "admin delete rx" on prescriptions;
create policy "staff read rx" on prescriptions for select to authenticated using (is_staff());
create policy "staff delete rx" on prescriptions for delete to authenticated using (is_staff());
drop policy if exists "admin read rx img" on storage.objects;
drop policy if exists "admin delete rx img" on storage.objects;
create policy "staff read rx img" on storage.objects for select to authenticated using (bucket_id='1' and is_staff());
create policy "staff delete rx img" on storage.objects for delete to authenticated using (bucket_id='1' and is_staff());
