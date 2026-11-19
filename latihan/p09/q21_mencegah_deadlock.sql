--Dijalankan di Sesi A
BEGIN;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 2
FOR UPDATE;

--Dijalankan di Sesi B
BEGIN;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 2
FOR UPDATE;

--Sesi B akan menunggu pada rekening 1, kemudian melanjutkan setelah Sesi A melakukan COMMIT