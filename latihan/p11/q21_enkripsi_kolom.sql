CREATE EXTENSION IF NOT EXISTS pgcrypto;

SET app.kunci_kolom = 'kunci-lab11-jangan-dipakai-di-produksi';
ALTER TABLE lab11.pelanggan ADD COLUMN IF NOT EXISTS rekening_enc bytea;
UPDATE lab11.pelanggan
SET rekening_enc = pgp_sym_encrypt(rekening, current_setting('app.kunci_kolom'))
WHERE id <= 1000;

SELECT count(*) AS baris_terenkripsi FROM lab11.pelanggan WHERE rekening_enc IS NOT NULL;

SELECT id,
       rekening                                                                AS asli,
       left(encode(rekening_enc, 'hex'), 24) || '...'                          AS ciphertext_hex,
       pgp_sym_decrypt(rekening_enc, current_setting('app.kunci_kolom'))       AS hasil_dekripsi,
       pgp_sym_decrypt(rekening_enc, current_setting('app.kunci_kolom')) = rekening AS cocok
FROM lab11.pelanggan WHERE id = 1;

SELECT pgp_sym_encrypt('x', 'k') = pgp_sym_encrypt('x', 'k') AS sama;
SELECT encode(pgp_sym_encrypt(rekening, current_setting('app.kunci_kolom')), 'hex') =
       encode(pgp_sym_encrypt(rekening, current_setting('app.kunci_kolom')), 'hex') AS sama_untuk_baris_id1
FROM lab11.pelanggan WHERE id = 1;

EXPLAIN (COSTS OFF)
SELECT id FROM lab11.pelanggan WHERE rekening_enc = pgp_sym_encrypt('x', 'k');

