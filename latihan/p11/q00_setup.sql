-- Diminta: membangun klaster tertutup dan memuat skema lab11.
-- Dipilih: jaringan internal: true, agar percobaan serangan tidak keluar ke internet.
-- Alternatif: jaringan bridge biasa; tidak dipilih karena melanggar aturan etika.
SELECT (SELECT count(*) FROM lab11.tenant)     AS tenant,
       (SELECT count(*) FROM lab11.pelanggan)  AS pelanggan,
       (SELECT count(*) FROM lab11.akun)       AS akun,
       (SELECT count(*) FROM lab11.transaksi)  AS transaksi;
SELECT tenant_id, count(*) FROM lab11.pelanggan GROUP BY 1 ORDER BY 1;