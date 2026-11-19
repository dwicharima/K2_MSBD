CREATE TABLE IF NOT EXISTS lab9.dokter_jaga (
    dokter_id INT PRIMARY KEY,
    nama TEXT NOT NULL,
    aktif BOOLEAN NOT NULL
);

TRUNCATE TABLE lab9.dokter_jaga;

INSERT INTO lab9.dokter_jaga (dokter_id, nama, aktif)
VALUES
    (1, 'Ani', TRUE),
    (2, 'Budi', TRUE);

SELECT * FROM lab9.dokter_jaga ORDER BY dokter_id;
