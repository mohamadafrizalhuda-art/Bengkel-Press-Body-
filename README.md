# Press Body Motor

Sistem informasi akuntansi pendapatan jasa bengkel berbasis HTML, CSS, JavaScript, Node.js native, dan Supabase Postgres.

## Struktur

- `frontend/` - halaman dashboard, stylesheet, dan JavaScript browser
- `backend/app.js` - server HTTP native dan proxy REST Supabase
- `database/schema.sql` - empat entitas ERD, relasi, policy, index, dan data awal
- `database/enable-master-inserts.sql` - grant dan policy input untuk pelanggan, kendaraan, layanan, dan pendapatan
- `database/operational-features.sql` - tabel booking/antrean tanpa menghapus history
- `database/admin-delete-policy.sql` - hak hapus khusus akun Supabase dengan role admin
- `.github/workflows/deploy-pages.yml` - deploy otomatis folder frontend ke GitHub Pages

## Menjalankan

1. Jalankan `database/schema.sql` melalui Supabase SQL Editor.
2. Jalankan `database/enable-master-inserts.sql` agar semua form bisa menambah pelanggan, kendaraan, layanan, dan transaksi. Aman dijalankan ulang dan tidak menghapus history.
3. Untuk kalender booking, antrean, status pengerjaan, dan kasir dari tiket selesai, jalankan `database/operational-features.sql`. Migrasi ini aman untuk data yang sudah ada.
4. Jika perlu hapus data, jalankan `database/admin-delete-policy.sql`. Ini hanya memberi hak DELETE ke role authenticated dengan app_metadata role admin; role anon secara eksplisit tidak diberi hak hapus.
5. Buat akun admin di Supabase **Authentication → Users**, lalu beri role admin melalui SQL Editor:

   `update auth.users set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb where email = 'EMAIL_ADMIN';`

   Ganti `EMAIL_ADMIN` dengan email akun admin. Keluar lalu login kembali di aplikasi agar token memuat role terbaru. Hapus hanya muncul untuk admin; foreign key akan mencegah penghapusan data yang masih terhubung ke history.
6. Buka `backend/app.js`, isi `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY`.
7. Pastikan Node.js 18 atau lebih baru tersedia.
8. Jalankan dari folder utama:

   `node backend/app.js`

9. Buka `http://localhost:3000`.

## Demo publik GitHub Pages

1. Push project ke branch `main` repository GitHub.
2. Di repository, buka **Settings → Pages** lalu pilih **GitHub Actions** sebagai build and deployment source.
3. Buka tab **Actions**, tunggu workflow `Deploy Press Body Motor to GitHub Pages` berstatus sukses.
4. URL demo muncul pada **Settings → Pages**. Format umumnya `https://USERNAME.github.io/NAMA-REPOSITORY/`.

Di GitHub Pages, frontend memanggil Supabase REST API secara langsung menggunakan publishable key; backend Node lokal tidak dijalankan oleh GitHub Pages. Publishable key memang boleh ada di frontend, tetapi jangan pernah memasukkan `service_role` key. Karena demo mengizinkan penulisan oleh role `anon`, siapa pun yang menemukan URL dapat mencoba membuat data; gunakan autentikasi dan policy RLS yang lebih ketat sebelum dipakai untuk data/operasi nyata.

Ringkasan menampilkan kalender kapasitas dan counter antrean; Layanan menyediakan penerimaan booking/walk-in dengan tiket, status pengerjaan, estimasi, panggilan lokal dan WhatsApp. Pendapatan menyediakan kasir tiket selesai, cetak nota (thermal atau simpan sebagai PDF lewat dialog browser), serta laporan CSV yang kompatibel dengan Excel.

Tidak diperlukan `package.json` atau file `.env.example`. Untuk produksi, simpan publishable key di secret manager dan tambahkan autentikasi pengguna.
