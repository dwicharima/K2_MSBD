-- Diminta: membuat tabel permintaan penghapusan data.
-- Dipilih: DEFAULT now() + interval '72 hours'.
-- Alternatif: GENERATED ALWAYS; tidak dipilih karena tidak didukung untuk ekspresi ini.

CREATE TABLE IF NOT EXISTS lab11.permintaan_hapus (
    id BIGSERIAL PRIMARY KEY,
    pelanggan_id INT NOT NULL,
    diterima_pada TIMESTAMPTZ NOT NULL DEFAULT now(),
    tenggat TIMESTAMPTZ NOT NULL
        DEFAULT now() + interval '72 hours',
    status TEXT NOT NULL DEFAULT 'menunggu'
);

-- Memeriksa struktur dan isi tabel.
SELECT *
FROM lab11.permintaan_hapus;


INSERT INTO lab11.permintaan_hapus (pelanggan_id)
VALUES (12), (13);

SELECT *
FROM lab11.permintaan_hapus
ORDER BY id;