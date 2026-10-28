BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE NOWAIT;