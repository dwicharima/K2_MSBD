-- Diminta: menyimpan metadata berbentuk JSONB dan mengambil atribut channel sebagai teks.
-- Dipilih: operator `->>` untuk langsung mendapatkan keluaran bertipe text.
-- Alternatif: operator `->`; tidak dipilih karena menghasilkan objek JSON (ditutupi tanda petik).

-- 1. Simpan payload JSONB
UPDATE lab5.rental_tx 
SET metadata = '{"channel":"web","device":"android"}'::jsonb 
WHERE rental_id = 1;

-- 2. Ambil nilai channel
SELECT rental_id, metadata ->> 'channel' AS kanal 
FROM lab5.rental_tx 
WHERE rental_id = 1;

/* Hasil Keluaran:
 rental_id | kanal 
-----------+-------
         1 | web
(1 row)
*/