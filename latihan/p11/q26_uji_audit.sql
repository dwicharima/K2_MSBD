-- Diminta: memilih data uji penyewa 1.
-- Dipilih: memeriksa ID dan transaksi sebelum mengubah data.
-- Alternatif: menghapus data tanpa pemeriksaan; tidak dipilih agar data tetap aman.

SELECT id, nama, tenant_id
FROM lab11.pelanggan
WHERE id = 3;

SELECT *
FROM lab11.transaksi
WHERE pelanggan_id = 3;

-- Diminta: menguji pencatatan UPDATE dan DELETE.
-- Dipilih: menjalankan perubahan sebagai app_portal penyewa 1.
-- Alternatif: menguji sebagai postgres; tidak dipilih karena tidak menguji peran aplikasi.

BEGIN;

SET LOCAL ROLE app_portal;
SET LOCAL app.tenant = '1';

-- Uji UPDATE.
UPDATE lab11.pelanggan
SET kota = kota
WHERE id = 3;

-- Ganti 13 dengan ID uji milik penyewa 1
-- yang sudah dipastikan tidak memiliki transaksi.
DELETE FROM lab11.pelanggan
WHERE id = 13;

COMMIT;

SELECT
    id,
    waktu,
    pelaku,
    aksi,
    nama_tabel,
    kunci,
    nilai_lama,
    nilai_baru
FROM lab11.jejak_audit
ORDER BY id DESC
LIMIT 20;

-- Uji membaca tabel audit.
SET ROLE app_portal;

SELECT *
FROM lab11.jejak_audit;

-- Uji memasukkan data audit secara langsung.
INSERT INTO lab11.jejak_audit (
    pelaku, aksi, nama_tabel, kunci
)
VALUES (
    'percobaan', 'INSERT', 'lab11.pelanggan', '999'
);

RESET ROLE;