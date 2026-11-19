CREATE TABLE IF NOT EXISTS lab9.antrean_pekerjaan (
    id INT PRIMARY KEY,
    status TEXT NOT NULL
);

INSERT INTO lab9.antrean_pekerjaan (id, status)
VALUES
    (1, 'menunggu'),
    (2, 'menunggu'),
    (3, 'menunggu')
ON CONFLICT (id) DO NOTHING;

SELECT * FROM lab9.antrean_pekerjaan
ORDER BY id;
