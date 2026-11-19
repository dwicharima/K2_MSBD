### Q26 — Isolation Level: REPEATABLE READ
**Sesi A**

latihan=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN

latihan=*# SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif = TRUE;
 dokter_aktif
--------------
            2
(1 row)

latihan=*# UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 1;
UPDATE 1

latihan=*# COMMIT;
COMMIT

**Sesi B**

latihan=# BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif = TRUE;
BEGIN
 dokter_aktif
--------------
            2
(1 row)

latihan=*# UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 2;
UPDATE 1

latihan=*# COMMIT;
COMMIT

Hasil Akhir

latihan=# SELECT * FROM lab9.dokter_jaga ORDER BY dokter_id;
 dokter_id | nama | aktif
-----------+------+-------
         1 | Ani  | f
         2 | Budi | f
(2 rows)