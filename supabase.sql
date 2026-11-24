-- Jalankan di Supabase: SQL Editor > New query > Run
-- Aman dijalankan berulang kali (termasuk jika sebelumnya memakai versi login email).

-- Bersihkan sisa versi lama
drop policy if exists "admin tambah" on public.state;
drop policy if exists "admin ubah" on public.state;
drop policy if exists "admin unggah foto" on storage.objects;
drop policy if exists "admin ubah foto" on storage.objects;
drop policy if exists "admin hapus foto" on storage.objects;
drop function if exists public.simpan_tps(int, jsonb);
drop function if exists public.is_admin() cascade;
drop table if exists public.admins;

create table if not exists public.state (
  id int primary key check (id = 1),
  data jsonb not null
);
create table if not exists public.pengaturan (
  id int primary key check (id = 1),
  pin_hash text not null
);

-- Semua orang boleh membaca. Tidak ada yang boleh menulis langsung; penulisan hanya lewat fungsi yang meminta PIN.
alter table public.state enable row level security;
alter table public.pengaturan enable row level security;
drop policy if exists "baca publik" on public.state;
create policy "baca publik" on public.state for select using (true);

create or replace function public.cek_pin(p_pin text) returns boolean
language plpgsql security definer set search_path = public, extensions as
$$ declare ok boolean;
begin
  select exists (select 1 from public.pengaturan where id = 1 and pin_hash = crypt(p_pin, pin_hash)) into ok;
  if not ok then perform pg_sleep(1); end if;
  return ok;
end $$;

create or replace function public.simpan_state(p_pin text, p_data jsonb) returns void
language plpgsql security definer set search_path = public, extensions as
$$ begin
  if not public.cek_pin(p_pin) then raise exception 'PIN salah'; end if;
  insert into public.state (id, data) values (1, p_data)
  on conflict (id) do update set data = excluded.data;
end $$;

-- Simpan satu TPS saja, agar dua petugas yang mengisi TPS berbeda tidak saling menimpa
create or replace function public.simpan_tps(p_pin text, p_idx int, p_val jsonb) returns void
language plpgsql security definer set search_path = public, extensions as
$$ begin
  if not public.cek_pin(p_pin) then raise exception 'PIN salah'; end if;
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

do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='state') then
    alter publication supabase_realtime add table public.state;
  end if;
end $$;
