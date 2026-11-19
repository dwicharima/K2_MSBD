-- Diminta: menghapus data pelanggan 12 dan 13.
-- Dipilih: memeriksa data dan transaksi sebelum penghapusan.
-- Alternatif: langsung menghapus tanpa pemeriksaan; tidak dipilih agar data uji terkontrol.

SELECT id, nama, tenant_id, nik
FROM lab11.pelanggan
WHERE id IN (12, 13);

SELECT *
FROM lab11.transaksi
WHERE pelanggan_id IN (12, 13);

BEGIN;

-- Mencatat permintaan penghapusan.
INSERT INTO lab11.permintaan_hapus (
    pelanggan_id,
    status
)
VALUES
    (12, 'diproses'),
    (13, 'diproses');

-- Menghapus transaksi terlebih dahulu.
DELETE FROM lab11.transaksi
WHERE pelanggan_id IN (12, 13);

-- Menghapus data pelanggan setelah transaksi.
DELETE FROM lab11.pelanggan
WHERE id IN (12, 13);

COMMIT;

-- Memeriksa tabel utama.
SELECT count(*) AS sisa_tabel_utama
FROM lab11.pelanggan
WHERE id IN (12, 13);

-- Memeriksa tabel transaksi.
SELECT count(*) AS sisa_transaksi
FROM lab11.transaksi
WHERE pelanggan_id IN (12, 13);

-- Memeriksa tabel jejak audit.
SELECT count(*) AS sisa_jejak_audit
FROM lab11.jejak_audit
WHERE kunci IN ('12', '13')
  AND nilai_lama ? 'nik';


SELECT *
FROM lab11.permintaan_hapus
WHERE pelanggan_id IN (12, 13)
ORDER BY id;