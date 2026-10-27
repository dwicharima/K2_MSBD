## Q11 — Tabel Ringkasan Anomali
Buat tabel ringkas: anomali, urutan kejadian, isolation level, hasil yang diamati, dan cara mencegah atau menangani masalah.

| Anomali | Urutan kejadian | Isolation level | Hasil yang diamati | Cara mencegah / menangani |
| --- | --- | --- | --- | --- |
| Dirty read | 1. A: UPDATE saldo tanpa COMMIT. 2. B: SELECT saldo. 3. A: ROLLBACK. | READ UNCOMMITTED (di PostgreSQL = READ COMMITTED) | B membaca 1000000 (bukan 700000). Tidak terjadi. | Tidak perlu penanganan khusus, PostgreSQL tidak pernah menampilkan data yang belum di-COMMIT. |
| Non-repeatable read | 1. A: BEGIN, SELECT. 2. B: UPDATE + COMMIT. 3. A: SELECT lagi. | READ COMMITTED | A membaca 1000000 lalu 1100000. Terjadi. | Gunakan REPEATABLE READ (atau SERIALIZABLE). |
| Non-repeatable read (pembanding) | Urutan sama dengan di atas. | REPEATABLE READ | A membaca 1000000 lalu tetap 1000000. Tidak terjadi. | Snapshot transaksi tetap sampai COMMIT. |
| Phantom read | 1. A: BEGIN, COUNT. 2. B: INSERT + COMMIT. 3. A: COUNT lagi. | READ COMMITTED | Jumlah berubah 2 menjadi 3. Terjadi. | Gunakan REPEATABLE READ (atau SERIALIZABLE). |
| Phantom read (pembanding) | Urutan sama dengan di atas. | REPEATABLE READ | Jumlah tetap 2. Tidak terjadi. | Snapshot transaksi tetap sampai COMMIT. |
| Lost update | 1. A dan B: SELECT (sama-sama 1000000). 2. A: UPDATE 1100000 + COMMIT. 3. B: UPDATE 1200000 + COMMIT. | READ COMMITTED | Saldo akhir 1200000, seharusnya 1300000. Update A hilang. | Update atomik `saldo = saldo + x` (hasil 1300000), atau `SELECT ... FOR UPDATE`, atau REPEATABLE READ + ulang transaksi bila gagal. |
