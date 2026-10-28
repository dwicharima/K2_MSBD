--Dijalankan di Sesi A
BEGIN;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

--Dijalankan di Sesi B
BEGIN;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

--Kembali ke Sesi A
COMMIT;

--Akhiri transaksi Sesi B
COMMIT;