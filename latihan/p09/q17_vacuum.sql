-- Q17: dijalankan MANUAL di dua sesi. VACUUM tidak boleh di dalam BEGIN.
-- [SESI A] persiapan; autovacuum dimatikan hanya untuk tabel demo ini
DROP TABLE IF EXISTS lab9.mvcc_demo;
CREATE TABLE lab9.mvcc_demo (id INT PRIMARY KEY, nilai INT) WITH (autovacuum_enabled = false);
INSERT INTO lab9.mvcc_demo VALUES (1, 0);
UPDATE lab9.mvcc_demo SET nilai = nilai + 1 WHERE id = 1;   -- jalankan 5 kali
SELECT * FROM lab9.mvcc_demo;
-- [SESI B] transaksi lama menahan snapshot
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM lab9.mvcc_demo;
-- [SESI A] Sesi B masih terbuka: "1 are dead but not yet removable"
UPDATE lab9.mvcc_demo SET nilai = nilai + 1 WHERE id = 1;
VACUUM (VERBOSE) lab9.mvcc_demo;
-- [SESI B]
COMMIT;
-- [SESI A] kini "0 are dead but not yet removable"
VACUUM (VERBOSE) lab9.mvcc_demo;
-- [PEMBERSIHAN]
DROP TABLE lab9.mvcc_demo;