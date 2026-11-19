
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TEMP TABLE akun_sandi AS
  SELECT id, nama_pengguna, NULL::text AS sandi_hash FROM lab11.akun;

UPDATE akun_sandi SET sandi_hash = crypt('rahasia123', gen_salt('bf', 8))
WHERE nama_pengguna IN ('sinta', 'ratna');
UPDATE akun_sandi SET sandi_hash = crypt('sandi-lain-456', gen_salt('bf', 8))
WHERE nama_pengguna IN ('bagas', 'yusuf');


SELECT nama_pengguna, sandi_hash FROM akun_sandi WHERE nama_pengguna IN ('sinta', 'ratna') ORDER BY id;

SELECT (SELECT sandi_hash FROM akun_sandi WHERE nama_pengguna = 'sinta')
    = (SELECT sandi_hash FROM akun_sandi WHERE nama_pengguna = 'ratna') AS hash_sama;

SELECT crypt('rahasia123', gen_salt('bf', 8)) AS hash_1,
      crypt('rahasia123', gen_salt('bf', 8)) AS hash_2;


SELECT md5('rahasia123') = md5('rahasia123') AS md5_sama;

SELECT nama_pengguna,
      sandi_hash = crypt('rahasia123', sandi_hash) AS cocok_benar,                      
      sandi_hash = crypt('salah',      sandi_hash) AS cocok_salah                        
FROM akun_sandi ORDER BY id;
