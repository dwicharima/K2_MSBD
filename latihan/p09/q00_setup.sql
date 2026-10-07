CREATE TABLE lab9.rekening (
    rekening_id INT PRIMARY KEY,
    pemilik TEXT NOT NULL,
    saldo NUMERIC(12,2) NOT NULL CHECK (saldo >= 0)
);

INSERT INTO lab9.rekening VALUES
(1, 'Ani', 1000000),
(2, 'Budi', 1000000)
ON CONFLICT (rekening_id) DO UPDATE
SET pemilik = EXCLUDED.pemilik,
    saldo = EXCLUDED.saldo;

SELECT * FROM lab9.rekening ORDER BY rekening_id;