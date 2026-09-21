-- Diminta: menambahkan EXCEPTION WHEN foreign_key_violation dengan pesan
--         yang lebih ramah ketika terjadi pelanggaran foreign key.
--
-- Dipilih: blok BEGIN ... EXCEPTION untuk menangkap kesalahan foreign key
--         dan menampilkan pesan yang mudah dipahami tanpa menampilkan
--         pesan error teknis secara langsung kepada pengguna.
--
-- Alternatif: membiarkan PostgreSQL menampilkan error bawaan; tidak dipilih
--             karena pesan tersebut lebih teknis dan kurang informatif
--             bagi pengguna aplikasi.

DO $$
BEGIN
    INSERT INTO lab4.harga_film (
        film_id,
        wilayah,
        harga,
        berlaku
    )
    VALUES (
        99999,
        'ID',
        10.00,
        daterange('2026-01-01', NULL)
    );

    RAISE NOTICE 'Data harga film berhasil ditambahkan.';

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE
            'Data gagal disimpan: film yang dipilih tidak ditemukan. '
            'Silakan gunakan film_id yang valid.';
END;
$$;