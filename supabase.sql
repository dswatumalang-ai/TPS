-- Jalankan di Supabase: SQL Editor > New query > Run

create table if not exists public.state (
  id int primary key check (id = 1),
  data jsonb not null
);
create table if not exists public.admins (
  user_id uuid primary key references auth.users on delete cascade
);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.admins where user_id = auth.uid()) $$;

alter table public.state enable row level security;
alter table public.admins enable row level security;

create policy "baca publik" on public.state for select using (true);
create policy "admin tambah" on public.state for insert to authenticated with check (public.is_admin());
create policy "admin ubah" on public.state for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Simpan satu TPS saja, agar dua admin yang input TPS berbeda tidak saling menimpa
create or replace function public.simpan_tps(p_idx int, p_val jsonb) returns void
language plpgsql security definer set search_path = public as
$$ begin
  if not public.is_admin() then raise exception 'bukan admin'; end if;
  update public.state set data = jsonb_set(data, array['tps', p_idx::text], p_val) where id = 1;
end $$;

insert into public.state (id, data) values (1, '{
 "desa":"Watumalang","kec":"Kec. Watumalang","per":"2027 – 2035",
 "calon":["Calon 01","Calon 02","Calon 03","Calon 04"],"foto":[],
 "tps":[
  {"nama":"TPS 1","l":350,"p":340,"masuk":false,"v":[0,0,0,0],"ts":0},
  {"nama":"TPS 2","l":350,"p":340,"masuk":false,"v":[0,0,0,0],"ts":0},
  {"nama":"TPS 3","l":350,"p":340,"masuk":false,"v":[0,0,0,0],"ts":0}]
}') on conflict (id) do nothing;

alter publication supabase_realtime add table public.state;

-- Penyimpanan foto calon
insert into storage.buckets (id, name, public) values ('foto', 'foto', true) on conflict (id) do nothing;
create policy "admin unggah foto" on storage.objects for insert to authenticated with check (bucket_id = 'foto' and public.is_admin());
create policy "admin ubah foto" on storage.objects for update to authenticated using (bucket_id = 'foto' and public.is_admin());
create policy "admin hapus foto" on storage.objects for delete to authenticated using (bucket_id = 'foto' and public.is_admin());
