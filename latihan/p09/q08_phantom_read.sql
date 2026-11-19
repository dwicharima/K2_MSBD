-- [SETUP TABEL EKSPERIMEN]
DROP TABLE IF EXISTS lab9.eksperimen_phantom;
CREATE TABLE lab9.eksperimen_phantom (
    id    SERIAL PRIMARY KEY,
    nama  TEXT NOT NULL,
    saldo NUMERIC(12,2) NOT NULL
);
INSERT INTO lab9.eksperimen_phantom (nama, saldo) VALUES
('Cici',  500000),
('Dedi', 1500000),
('Eka',  2000000);
SELECT * FROM lab9.eksperimen_phantom ORDER BY id;

----------- 8a ----------
-- LANGKAH 1 [SESI A]
BEGIN;
SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;

-- LANGKAH 2 [SESI B]
INSERT INTO lab9.eksperimen_phantom (nama, saldo) VALUES ('Fani', 3000000);

-- LANGKAH 3 [SESI A]
SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;
COMMIT;

-- [RESET sebelum 8b]
DELETE FROM lab9.eksperimen_phantom WHERE nama = 'Fani';

----------- 8b ----------
-- LANGKAH 4 [SESI A]
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;

-- LANGKAH 5 [SESI B]
INSERT INTO lab9.eksperimen_phantom (nama, saldo) VALUES ('Gani', 3500000);

-- LANGKAH 6 [SESI A]
SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;
COMMIT;

-- LANGKAH 7 [SESI A]
SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000; 

