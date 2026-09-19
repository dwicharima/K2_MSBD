-- Masukkan data rusak dulu, biar kontrasnya kelihatan
INSERT INTO lab4.film (title, rental_rate, rating) VALUES ('Film Rusak Q14', -5.00, 'PG');

-- Tahap 1: tambahkan aturan tanpa validasi data lama (cepat, tidak lock lama)
ALTER TABLE lab4.film
    ADD CONSTRAINT film_rental_rate_non_negatif
    CHECK (rental_rate >= 0) NOT VALID;
-- ^ ini BERHASIL walau ada baris negatif, karena NOT VALID cuma menjaga baris baru

-- Buktikan validasi eksplisit gagal
ALTER TABLE lab4.film VALIDATE CONSTRAINT film_rental_rate_non_negatif;
-- ERROR: check constraint ... is violated by some row

-- Perbaiki datanya
UPDATE lab4.film SET rental_rate = 5.00 WHERE title = 'Film Rusak Q14';

-- Ulangi validasi -> sekarang sukses
ALTER TABLE lab4.film VALIDATE CONSTRAINT film_rental_rate_non_negatif;