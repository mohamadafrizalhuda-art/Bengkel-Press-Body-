-- Jalankan di Supabase SQL Editor untuk mengaktifkan hapus khusus admin.
-- Tidak membuka DELETE untuk role anon dan tidak mengubah/menghapus data.
-- Buat akun admin di Supabase Auth, lalu set app_metadata JSON menjadi {"role":"admin"}.

grant usage on schema public to authenticated;
grant select on table public.pelanggan, public.kendaraan, public.layanan, public.pendapatan, public.antrian_servis to authenticated;
grant delete on table public.pelanggan, public.kendaraan, public.layanan, public.pendapatan, public.antrian_servis to authenticated;
revoke delete on table public.pelanggan, public.kendaraan, public.layanan, public.pendapatan, public.antrian_servis from anon, public;

alter table public.pelanggan enable row level security;
alter table public.kendaraan enable row level security;
alter table public.layanan enable row level security;
alter table public.pendapatan enable row level security;
alter table public.antrian_servis enable row level security;

drop policy if exists "admin delete pelanggan" on public.pelanggan;
drop policy if exists "admin delete kendaraan" on public.kendaraan;
drop policy if exists "admin delete layanan" on public.layanan;
drop policy if exists "admin delete pendapatan" on public.pendapatan;
drop policy if exists "admin delete antrian" on public.antrian_servis;
drop policy if exists "admin read pelanggan" on public.pelanggan;
drop policy if exists "admin read kendaraan" on public.kendaraan;
drop policy if exists "admin read layanan" on public.layanan;
drop policy if exists "admin read pendapatan" on public.pendapatan;
drop policy if exists "admin read antrian" on public.antrian_servis;

create policy "admin read pelanggan" on public.pelanggan
  for select to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "admin read kendaraan" on public.kendaraan
  for select to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "admin read layanan" on public.layanan
  for select to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "admin read pendapatan" on public.pendapatan
  for select to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "admin read antrian" on public.antrian_servis
  for select to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

create policy "admin delete pelanggan" on public.pelanggan
  for delete to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "admin delete kendaraan" on public.kendaraan
  for delete to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "admin delete layanan" on public.layanan
  for delete to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "admin delete pendapatan" on public.pendapatan
  for delete to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "admin delete antrian" on public.antrian_servis
  for delete to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
