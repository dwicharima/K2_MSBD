SELECT count(*) AS kombinasi_sebelum
FROM (SELECT DISTINCT kota, lahir FROM lab11.pelanggan) s;

SELECT count(*) AS kombinasi_hanya_satu_orang
FROM (SELECT kota, lahir FROM lab11.pelanggan GROUP BY kota, lahir HAVING count(*) = 1) s;

SELECT count(*) AS kombinasi_sesudah
FROM (SELECT DISTINCT kota, lahir_tahun FROM lab11.v_pelanggan_samar) s;

SELECT min(n) AS kelompok_terkecil
FROM (SELECT count(*) AS n FROM lab11.v_pelanggan_samar GROUP BY kota, lahir_tahun) s; 

SELECT round(100.0 * (a.n - b.n) / a.n, 2) AS persen_turun
FROM (SELECT count(*) AS n FROM (SELECT DISTINCT kota, lahir FROM lab11.pelanggan) x) a,
    (SELECT count(*) AS n FROM (SELECT DISTINCT kota, lahir_tahun FROM lab11.v_pelanggan_samar) y) b;

SELECT lahir AS lahir_target
FROM lab11.pelanggan WHERE kota = 'Medan'
GROUP BY lahir HAVING count(*) = 1 ORDER BY lahir LIMIT 1 \gset

SELECT count(*) AS n_a, sum(saldo) AS total_a FROM lab11.pelanggan WHERE kota = 'Medan';

SELECT count(*) AS n_b, sum(saldo) AS total_b FROM lab11.pelanggan
WHERE kota = 'Medan' AND lahir <> :'lahir_target';
SELECT (SELECT count(*) FROM lab11.pelanggan WHERE kota = 'Medan')
    - (SELECT count(*) FROM lab11.pelanggan WHERE kota = 'Medan' AND lahir <> :'lahir_target') AS selisih_baris,
      (SELECT sum(saldo) FROM lab11.pelanggan WHERE kota = 'Medan')
    - (SELECT sum(saldo) FROM lab11.pelanggan WHERE kota = 'Medan' AND lahir <> :'lahir_target') AS saldo_terungkap;
SELECT id, nama, saldo FROM lab11.pelanggan WHERE kota = 'Medan' AND lahir = :'lahir_target';
