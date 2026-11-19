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
WHERE rekening_id = 2
FOR UPDATE;

--Kembali ke Sesi A
SELECT *
FROM lab9.rekening
WHERE rekening_id = 2
FOR UPDATE;

--Kembali ke Sesi B
SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

--Salah satu sesi akan menunggu sesi lainnya untuk melepaskan kunci, sehingga terjadi deadlock.