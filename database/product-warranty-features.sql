-- Jalankan setelah schema.sql dan operational-features.sql.
-- Migration additive: tidak menghapus data history.

alter table public.layanan
  add column if not exists masa_garansi_bulan smallint not null default 0
  check (masa_garansi_bulan >= 0);

update public.layanan
set masa_garansi_bulan = case
  when kategori = 'body repair' then 3
  when kategori = 'pengecatan' then 1
  else 0
end
where masa_garansi_bulan = 0;

create table if not exists public.produk (
  id uuid primary key default gen_random_uuid(),
  sku varchar(24) not null unique,
  nama_produk varchar(120) not null,
  kategori varchar(60) not null default 'umum',
  harga_modal numeric(14,2) not null default 0 check (harga_modal >= 0),
  harga_jual numeric(14,2) not null check (harga_jual >= 0),
  stok integer not null default 0 check (stok >= 0),
  stok_minimum integer not null default 0 check (stok_minimum >= 0),
  aktif boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.penjualan_produk (
  id uuid primary key default gen_random_uuid(),
  nomor_penjualan varchar(36) not null unique default ('PRD-' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') || '-' || upper(substr(gen_random_uuid()::text, 1, 4))),
  pendapatan_id uuid references public.pendapatan(id) on delete restrict,
  pelanggan_id uuid references public.pelanggan(id) on delete restrict,
  kendaraan_id uuid,
  tanggal timestamptz not null default now(),
  total numeric(14,2) not null default 0 check (total >= 0),
  metode_pembayaran varchar(15) not null default 'tunai' check (metode_pembayaran in ('tunai', 'transfer', 'qris', 'debit')),
  catatan text,
  created_at timestamptz not null default now(),
  constraint penjualan_kendaraan_pelanggan_fk foreign key (kendaraan_id, pelanggan_id) references public.kendaraan(id, pelanggan_id) on delete restrict
);

create table if not exists public.detail_penjualan_produk (
  id uuid primary key default gen_random_uuid(),
  penjualan_id uuid not null references public.penjualan_produk(id) on delete cascade,
  produk_id uuid not null references public.produk(id) on delete restrict,
  nama_produk_snapshot varchar(120) not null,
  jumlah integer not null check (jumlah > 0),
  harga_satuan numeric(14,2) not null check (harga_satuan >= 0),
  subtotal numeric(14,2) generated always as (jumlah * harga_satuan) stored,
  created_at timestamptz not null default now()
);

create table if not exists public.garansi (
  id uuid primary key default gen_random_uuid(),
  nomor_garansi varchar(36) not null unique default ('GAR-' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') || '-' || upper(substr(gen_random_uuid()::text, 1, 4))),
  pendapatan_id uuid not null unique references public.pendapatan(id) on delete restrict,
  pelanggan_id uuid not null references public.pelanggan(id) on delete restrict,
  kendaraan_id uuid not null,
  layanan_id uuid not null references public.layanan(id) on delete restrict,
  mulai_berlaku date not null default current_date,
  masa_berlaku_bulan smallint not null check (masa_berlaku_bulan > 0),
  berakhir_pada date not null,
  created_at timestamptz not null default now(),
  constraint garansi_kendaraan_pelanggan_fk foreign key (kendaraan_id, pelanggan_id) references public.kendaraan(id, pelanggan_id) on delete restrict
);

create table if not exists public.klaim_garansi (
  id uuid primary key default gen_random_uuid(),
  nomor_klaim varchar(36) not null unique default ('KLM-' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') || '-' || upper(substr(gen_random_uuid()::text, 1, 4))),
  garansi_id uuid not null references public.garansi(id) on delete restrict,
  antrian_id uuid references public.antrian_servis(id) on delete restrict,
  tanggal_klaim timestamptz not null default now(),
  keluhan text not null,
  status varchar(12) not null default 'diajukan' check (status in ('diajukan', 'dikerjakan', 'selesai', 'ditolak')),
  biaya numeric(14,2) not null default 0 check (biaya = 0),
  created_at timestamptz not null default now()
);

alter table public.antrian_servis drop constraint if exists antrian_servis_tipe_kedatangan_check;
alter table public.antrian_servis add constraint antrian_servis_tipe_kedatangan_check check (tipe_kedatangan in ('booking', 'walk-in', 'klaim'));
alter table public.antrian_servis add column if not exists klaim_garansi_id uuid references public.klaim_garansi(id) on delete restrict;

create index if not exists idx_produk_aktif_stok on public.produk(aktif, stok);
create index if not exists idx_penjualan_tanggal on public.penjualan_produk(tanggal desc);
create index if not exists idx_penjualan_pelanggan on public.penjualan_produk(pelanggan_id);
create index if not exists idx_detail_penjualan_produk on public.detail_penjualan_produk(produk_id);
create index if not exists idx_garansi_kendaraan on public.garansi(kendaraan_id);
create index if not exists idx_garansi_expiry on public.garansi(berakhir_pada);
create index if not exists idx_klaim_tanggal on public.klaim_garansi(tanggal_klaim desc);

create or replace view public.status_garansi as
select g.*, p.nama as nama_pelanggan, p.no_telepon, k.nomor_polisi, k.merk, k.tipe,
       l.nama_layanan,
       case when current_date <= g.berakhir_pada then 'aktif' else 'expired' end as status_garansi
from public.garansi g
join public.pelanggan p on p.id = g.pelanggan_id
join public.kendaraan k on k.id = g.kendaraan_id
join public.layanan l on l.id = g.layanan_id;

create or replace function public.buat_garansi_pendapatan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  service_months smallint;
begin
  select masa_garansi_bulan into service_months from public.layanan where id = new.layanan_id;
  if coalesce(service_months, 0) > 0 and new.status_pembayaran = 'lunas' then
    insert into public.garansi (pendapatan_id, pelanggan_id, kendaraan_id, layanan_id, masa_berlaku_bulan, mulai_berlaku, berakhir_pada)
    values (new.id, new.pelanggan_id, new.kendaraan_id, new.layanan_id, service_months, new.tanggal, (new.tanggal + make_interval(months => service_months))::date)
    on conflict (pendapatan_id) do nothing;
  end if;
  return new;
end;
$$;
drop trigger if exists pendapatan_buat_garansi on public.pendapatan;
create trigger pendapatan_buat_garansi after insert on public.pendapatan for each row execute function public.buat_garansi_pendapatan();

insert into public.garansi (pendapatan_id, pelanggan_id, kendaraan_id, layanan_id, masa_berlaku_bulan, mulai_berlaku, berakhir_pada)
select p.id, p.pelanggan_id, p.kendaraan_id, p.layanan_id, l.masa_garansi_bulan, p.tanggal,
       (p.tanggal + make_interval(months => l.masa_garansi_bulan))::date
from public.pendapatan p
join public.layanan l on l.id = p.layanan_id
where p.status_pembayaran = 'lunas'
  and l.masa_garansi_bulan > 0
on conflict (pendapatan_id) do nothing;

create or replace function public.catat_penjualan_produk(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  sale_id uuid;
  sale_row public.penjualan_produk%rowtype;
  item jsonb;
  product_row public.produk%rowtype;
  qty integer;
  sale_total numeric(14,2) := 0;
  result_items jsonb;
begin
  if jsonb_typeof(p_payload->'items') <> 'array' or jsonb_array_length(p_payload->'items') = 0 then
    raise exception using errcode = '22023', message = 'Pilih minimal satu produk.';
  end if;

  insert into public.penjualan_produk (pendapatan_id, pelanggan_id, kendaraan_id, metode_pembayaran, catatan)
  values (nullif(p_payload->>'pendapatan_id', '')::uuid,
          nullif(p_payload->>'pelanggan_id', '')::uuid,
          nullif(p_payload->>'kendaraan_id', '')::uuid,
          coalesce(nullif(p_payload->>'metode_pembayaran', ''), 'tunai'),
          nullif(p_payload->>'catatan', ''))
  returning id into sale_id;

  for item in select value from jsonb_array_elements(p_payload->'items') loop
    qty := (item->>'jumlah')::integer;
    if qty <= 0 then raise exception using errcode = '22023', message = 'Jumlah produk harus lebih dari nol.'; end if;
    select * into product_row from public.produk where id = (item->>'produk_id')::uuid and aktif = true for update;
    if not found then raise exception using errcode = '23503', message = 'Produk tidak ditemukan atau tidak aktif.'; end if;
    if product_row.stok < qty then raise exception using errcode = '23514', message = format('Stok %s tidak cukup. Sisa stok: %s.', product_row.nama_produk, product_row.stok); end if;
    update public.produk set stok = stok - qty, updated_at = now() where id = product_row.id;
    insert into public.detail_penjualan_produk (penjualan_id, produk_id, nama_produk_snapshot, jumlah, harga_satuan)
    values (sale_id, product_row.id, product_row.nama_produk, qty, product_row.harga_jual);
    sale_total := sale_total + (qty * product_row.harga_jual);
  end loop;

  update public.penjualan_produk set total = sale_total where id = sale_id returning * into sale_row;
  select coalesce(jsonb_agg(to_jsonb(d)), '[]'::jsonb) into result_items
  from public.detail_penjualan_produk d where d.penjualan_id = sale_id;
  return jsonb_build_object('penjualan', to_jsonb(sale_row), 'items', result_items);
end;
$$;

create or replace function public.catat_transaksi_bengkel(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  income_row public.pendapatan%rowtype;
  sale_result jsonb := null;
  warranty_row jsonb := null;
begin
  insert into public.pendapatan (pelanggan_id, kendaraan_id, layanan_id, tanggal, subtotal, diskon, metode_pembayaran, status_pembayaran, catatan)
  values ((p_payload->>'pelanggan_id')::uuid, (p_payload->>'kendaraan_id')::uuid, (p_payload->>'layanan_id')::uuid,
          coalesce(nullif(p_payload->>'tanggal', '')::date, current_date),
          coalesce(nullif(p_payload->>'total', '')::numeric, 0),
          coalesce(nullif(p_payload->>'diskon', '')::numeric, 0),
          coalesce(nullif(p_payload->>'metode_pembayaran', ''), 'tunai'), 'lunas', nullif(p_payload->>'catatan', ''))
  returning * into income_row;

  if jsonb_typeof(p_payload->'items') = 'array' and jsonb_array_length(p_payload->'items') > 0 then
    sale_result := public.catat_penjualan_produk(p_payload || jsonb_build_object('pendapatan_id', income_row.id));
  end if;

  select to_jsonb(g) into warranty_row from public.garansi g where g.pendapatan_id = income_row.id;
  return jsonb_build_object('pendapatan', to_jsonb(income_row), 'penjualan_produk', sale_result, 'garansi', warranty_row);
end;
$$;

create or replace function public.buat_klaim_garansi(p_garansi_id uuid, p_keluhan text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  warranty_row public.garansi%rowtype;
  claim_id uuid;
  queue_row public.antrian_servis%rowtype;
  claim_row public.klaim_garansi%rowtype;
begin
  select * into warranty_row from public.garansi where id = p_garansi_id for update;
  if not found then raise exception using errcode = 'P0002', message = 'Garansi tidak ditemukan.'; end if;
  if current_date > warranty_row.berakhir_pada then raise exception using errcode = '22023', message = 'Garansi sudah expired.'; end if;
  if nullif(trim(p_keluhan), '') is null then raise exception using errcode = '22023', message = 'Keluhan wajib diisi.'; end if;

  insert into public.klaim_garansi (garansi_id, keluhan, biaya) values (warranty_row.id, trim(p_keluhan), 0) returning id into claim_id;
  insert into public.antrian_servis (tipe_kedatangan, pelanggan_id, kendaraan_id, layanan_id, jadwal_mulai, status, catatan, klaim_garansi_id)
  values ('klaim', warranty_row.pelanggan_id, warranty_row.kendaraan_id, warranty_row.layanan_id, now(), 'menunggu', 'Klaim ' || p_keluhan, claim_id)
  returning * into queue_row;
  update public.klaim_garansi set antrian_id = queue_row.id where id = claim_id returning * into claim_row;
  return jsonb_build_object('klaim', to_jsonb(claim_row), 'antrian', to_jsonb(queue_row), 'biaya', 0);
end;
$$;

create or replace function public.update_status_klaim(p_claim_id uuid, p_status text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare result_row public.klaim_garansi%rowtype;
begin
  if p_status not in ('diajukan', 'dikerjakan', 'selesai', 'ditolak') then raise exception using errcode = '22023', message = 'Status klaim tidak valid.'; end if;
  update public.klaim_garansi set status = p_status where id = p_claim_id returning * into result_row;
  if not found then raise exception using errcode = 'P0002', message = 'Klaim tidak ditemukan.'; end if;
  if result_row.antrian_id is not null then
    update public.antrian_servis set status = case when p_status = 'dikerjakan' then 'dikerjakan' when p_status = 'selesai' then 'selesai' else status end where id = result_row.antrian_id;
  end if;
  return to_jsonb(result_row);
end;
$$;

create or replace function public.tambah_stok_produk(p_produk_id uuid, p_jumlah integer)
returns public.produk
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare result_row public.produk%rowtype;
begin
  if coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') <> 'admin' then
    raise exception using errcode = '42501', message = 'Hanya admin yang dapat menambah stok produk.';
  end if;
  if p_jumlah <= 0 then raise exception using errcode = '22023', message = 'Jumlah stok masuk harus lebih dari nol.'; end if;
  update public.produk set stok = stok + p_jumlah, updated_at = now() where id = p_produk_id and aktif = true returning * into result_row;
  if not found then raise exception using errcode = 'P0002', message = 'Produk tidak ditemukan atau tidak aktif.'; end if;
  return result_row;
end;
$$;

alter table public.produk enable row level security;
alter table public.penjualan_produk enable row level security;
alter table public.detail_penjualan_produk enable row level security;
alter table public.garansi enable row level security;
alter table public.klaim_garansi enable row level security;

 grant usage on schema public to anon, authenticated;
grant select, insert on public.produk to anon, authenticated;
grant select on public.penjualan_produk, public.detail_penjualan_produk, public.garansi, public.klaim_garansi, public.status_garansi to anon, authenticated;
grant execute on function public.catat_penjualan_produk(jsonb) to anon, authenticated;
grant execute on function public.catat_transaksi_bengkel(jsonb) to anon, authenticated;
grant execute on function public.buat_klaim_garansi(uuid, text) to anon, authenticated;
grant execute on function public.update_status_klaim(uuid, text) to anon, authenticated;
revoke all on function public.tambah_stok_produk(uuid, integer) from public, anon;
grant execute on function public.tambah_stok_produk(uuid, integer) to authenticated;

drop policy if exists "public read produk" on public.produk;
drop policy if exists "public insert produk" on public.produk;
drop policy if exists "public read penjualan produk" on public.penjualan_produk;
drop policy if exists "public read detail penjualan produk" on public.detail_penjualan_produk;
drop policy if exists "public read garansi" on public.garansi;
drop policy if exists "public read klaim garansi" on public.klaim_garansi;
create policy "public read produk" on public.produk for select to anon, authenticated using (aktif = true);
create policy "public insert produk" on public.produk for insert to anon, authenticated with check (true);
create policy "public read penjualan produk" on public.penjualan_produk for select to anon, authenticated using (true);
create policy "public read detail penjualan produk" on public.detail_penjualan_produk for select to anon, authenticated using (true);
create policy "public read garansi" on public.garansi for select to anon, authenticated using (true);
create policy "public read klaim garansi" on public.klaim_garansi for select to anon, authenticated using (true);
