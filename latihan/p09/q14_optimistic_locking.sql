-- Q14: dijalankan MANUAL di dua sesi.
-- [PERSIAPAN] tabel bantu (struktur lab9.rekening tidak diubah)
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);
DROP TABLE IF EXISTS lab9.rekening_versi;
CREATE TABLE lab9.rekening_versi (
    rekening_id INT PRIMARY KEY,
    pemilik     TEXT NOT NULL,
    saldo       NUMERIC(12,2) NOT NULL CHECK (saldo >= 0),
    version_no  INT NOT NULL DEFAULT 1
);
INSERT INTO lab9.rekening_versi (rekening_id, pemilik, saldo)
SELECT rekening_id, pemilik, saldo FROM lab9.rekening;

-- 14a. version_no
-- [SESI A]
BEGIN;
SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
-- [SESI B]
BEGIN;
SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
-- [SESI A]
UPDATE lab9.rekening_versi SET saldo = 1100000, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 1;
COMMIT;
-- [SESI B] hasil UPDATE 0 -> konflik terdeteksi
UPDATE lab9.rekening_versi SET saldo = 1200000, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 1;
ROLLBACK;
-- [SESI B] ulangi
BEGIN;
SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
UPDATE lab9.rekening_versi SET saldo = 1300000, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 2;
COMMIT;
-- [HASIL] 1300000, versi 3
SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;

-- 14b. nilai saldo sebagai kondisi
-- [SESI A]
BEGIN;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI B]
BEGIN;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI A]
UPDATE lab9.rekening SET saldo = 1100000 WHERE rekening_id = 1 AND saldo = 1000000;
COMMIT;
-- [SESI B] hasil UPDATE 0
UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1 AND saldo = 1000000;
ROLLBACK;
-- [RESET]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);

-- 14c. ABA
-- [SESI A]
UPDATE lab9.rekening_versi SET saldo = 1000000, version_no = 1 WHERE rekening_id = 1;
-- [SESI B]
BEGIN;
SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
-- [SESI A]
UPDATE lab9.rekening_versi SET saldo = saldo + 100000, version_no = version_no + 1 WHERE rekening_id = 1;
UPDATE lab9.rekening_versi SET saldo = saldo - 100000, version_no = version_no + 1 WHERE rekening_id = 1;
SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
-- [SESI B] version_no = 1 -> UPDATE 0; saldo = 1000000 -> UPDATE 1
UPDATE lab9.rekening_versi SET saldo = 1200000, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 1;
UPDATE lab9.rekening_versi SET saldo = 1200000, version_no = version_no + 1
WHERE rekening_id = 1 AND saldo = 1000000;
ROLLBACK;

-- [PEMBERSIHAN]
DROP TABLE lab9.rekening_versi;
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);
