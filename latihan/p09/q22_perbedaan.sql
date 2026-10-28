--Dijalankan di Sesi A
BEGIN;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

-- Biarkan transaksi tetap terbuka.

--Dijalankan di Sesi B
BEGIN;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

--Akhiri transaksi Sesi A
COMMIT;

--Selesaikan transaksi Sesi B
COMMIT;