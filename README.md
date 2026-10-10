<div align="center">
  <img src="https://raw.githubusercontent.com/mohamadafrizalhuda-art/Bengkel-Press-Body-/main/frontend/logo/logo-horizontal-header-hijau%20%281%29.png" alt="Logo Press Body Motor" width="560">
  <h1>Sistem Informasi Akuntansi Press Body Motor</h1>
  <p>Aplikasi web untuk membantu bengkel mencatat pendapatan, mengelola pelanggan dan kendaraan, serta memantau aktivitas layanan dalam satu tempat.</p>
  <p>
    <a href="https://mohamadafrizalhuda-art.github.io/Bengkel-Press-Body-/"><strong>🌐 Buka Demo Website</strong></a>
  </p>
  <p>
    <img src="https://img.shields.io/badge/Frontend-HTML%20%7C%20CSS%20%7C%20JavaScript-e9a23b?style=flat-square" alt="Frontend HTML CSS JavaScript">
    <img src="https://img.shields.io/badge/Backend-Node.js%20Native-315b49?style=flat-square" alt="Backend Node.js">
    <img src="https://img.shields.io/badge/Database-Supabase%20PostgreSQL-315b49?style=flat-square" alt="Database Supabase PostgreSQL">
    <img src="https://img.shields.io/badge/Deploy-GitHub%20Pages-e9a23b?style=flat-square" alt="Deployment GitHub Pages">
  </p>
</div>

## Tentang Proyek

Press Body Motor adalah aplikasi pencatatan operasional dan pendapatan jasa bengkel. Aplikasi menyediakan dashboard, data pelanggan dan kendaraan, katalog layanan, booking dan antrean, serta riwayat transaksi dengan struk yang bisa dicetak atau dibagikan.

Demo publik: **[mohamadafrizalhuda-art.github.io/Bengkel-Press-Body-](https://mohamadafrizalhuda-art.github.io/Bengkel-Press-Body-/)**

## Teknologi

| Bagian | Teknologi |
|---|---|
| Antarmuka | HTML, CSS, JavaScript tanpa framework |
| Backend lokal | Node.js native HTTP server |
| Database dan API | Supabase PostgreSQL dan REST API |
| Autentikasi admin | Supabase Auth dengan role admin |
| Hosting frontend | GitHub Pages melalui GitHub Actions |
| Font dan ikon | Plus Jakarta Sans, DM Sans, ikon SVG |

## Fitur

| Menu | Fitur |
|---|---|
| **Ringkasan** | Ringkasan pendapatan dan transaksi, grafik pendapatan, kalender booking, serta kapasitas bengkel. |
| **Layanan** | Catat booking atau walk-in, pantau antrean dan status pengerjaan, estimasi layanan, serta panggil pelanggan. |
| **Pendapatan** | Catat transaksi, isi harga dari katalog layanan lalu sesuaikan bila diperlukan, dan lihat aktivitas transaksi terbaru. |
| **Riwayat struk** | Buka struk dari transaksi, pilih kertas Thermal 58 mm, Thermal 80 mm, atau A4/PDF, cetak, dan bagikan melalui WhatsApp. |
| **Laporan** | Filter pendapatan berdasarkan periode dan metode pembayaran, lalu cetak atau ekspor CSV yang kompatibel dengan Excel. |
| **Data master** | Kelola data pelanggan, kendaraan, dan katalog layanan untuk digunakan pada transaksi. |
| **Akses admin** | Login admin untuk menghapus data yang diizinkan oleh policy database. |

## Alur Penggunaan

1. Siapkan database Supabase menggunakan SQL yang tersedia di folder `database/`.
2. Tambahkan data pelanggan, kendaraan, dan layanan pada **Data Master**.
3. Catat booking/antrean pada menu **Layanan**, atau langsung catat pembayaran pada menu **Pendapatan**.
4. Buka struk dari nominal transaksi untuk melihat riwayat, mencetak struk, atau membagikannya.
5. Gunakan **Laporan Pendapatan** untuk memfilter dan mengekspor transaksi.

## Menjalankan Secara Lokal

### 1. Siapkan database

Jalankan file SQL di Supabase SQL Editor sesuai urutan berikut:

1. `database/schema.sql`
2. `database/enable-master-inserts.sql`
3. `database/operational-features.sql` untuk kalender booking, antrean, dan status pengerjaan.
4. `database/product-warranty-features.sql` untuk fitur produk dan garansi.
5. `database/admin-delete-policy.sql` bila penghapusan data oleh admin diperlukan.

### 2. Konfigurasi Supabase

Isi `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` pada `backend/app.js` dan `frontend/app.js` dengan konfigurasi project Supabase milikmu. Gunakan **publishable/anon key** untuk frontend. Jangan pernah memasukkan `service_role` key ke frontend atau repository.

### 3. Jalankan server

Pastikan Node.js 18 atau lebih baru telah terpasang, lalu jalankan dari folder utama project:

```powershell
node backend/app.js
```

Buka [http://localhost:3000](http://localhost:3000).

## Deploy dan Demo Publik

Frontend di-deploy ke GitHub Pages secara otomatis setiap kali ada push ke branch `main`. Workflow deploy berada di `.github/workflows/deploy-pages.yml`.

**[Buka demo Press Body Motor](https://mohamadafrizalhuda-art.github.io/Bengkel-Press-Body-/)**

## Struktur Proyek

```text
.
├── .github/workflows/deploy-pages.yml
├── backend/app.js
├── database/
│   ├── schema.sql
│   ├── enable-master-inserts.sql
│   ├── operational-features.sql
│   ├── product-warranty-features.sql
│   └── admin-delete-policy.sql
├── frontend/
│   ├── index.html
│   ├── styles.css
│   ├── app.js
│   └── logo/
└── start-server.ps1
```

## Catatan Keamanan

GitHub Pages hanya meng-host frontend; backend Node.js lokal tidak berjalan di sana. Frontend mengakses Supabase REST API secara langsung, sehingga publishable key dapat terlihat oleh pengunjung. Atur Supabase Row Level Security (RLS) dengan hati-hati: kebijakan yang mengizinkan role `anon` menulis data dapat digunakan oleh siapa pun yang mengakses demo. Jangan gunakan konfigurasi demo untuk data pelanggan atau operasional nyata tanpa autentikasi dan policy yang sesuai.
