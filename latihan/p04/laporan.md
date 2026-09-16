# Laporan Latihan Kelompok Pertemuan 4

| Nama | NIM | Kontribusi | Commit |
|------|-----|------------|
| Rasyd Arija Azron Ritonga | 251402020 |  |  |
| Fakhry Adrian Daulay | 251402053 |  |  |
| Dwi Charima Husni | 251402088 |  |  |
| Agnes Natalia Br Siregar| 251402108 | |  |
| Abdullah Zufar Aulia Nasution | 251402111 |  |  |

### Q1
Perintah :

CREATE SCHEMA IF NOT EXISTS lab4;
SET search_path = lab4, public;

DROP TABLE IF EXISTS lab4.jejak_akses CASCADE;
DROP TABLE IF EXISTS lab4.film CASCADE;

CREATE TABLE lab4.film (
    film_id serial PRIMARY KEY,
    title text NOT NULL,
    description text,
    release_year integer,
    language_id smallint,
    rental_duration smallint DEFAULT 3,
    rental_rate numeric(4,2) NOT NULL DEFAULT 4.99,
    length smallint,
    replacement_cost numeric(5,2),
    rating text DEFAULT 'G',
    last_update timestamp DEFAULT now()
);

INSERT INTO lab4.film (title, rental_rate, rating) VALUES
('Film A', 0.99, 'G'),
('Film B', 4.99, 'R'),
('Film C', 0.50, 'PG');

CREATE TABLE lab4.jejak_akses (
    akses_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    waktu timestamptz NOT NULL,
    kanal text NOT NULL
);

INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1,
       now() - (random() * 365) * interval '1 day',
       (ARRAY['web','android','ios','kiosk'])[(random() * 3)::int + 1]
FROM generate_series(1, 500000);

ANALYZE lab4.jejak_akses;
SELECT count(*) FROM lab4.jejak_akses;

Keluaran :
AGNES@LAPTOP-1T3ANVB7 MINGW64 ~/msbd-2026 (latihan/p04-sql2)
$ docker exec -i msbd-pg psql -U msbd -d latihan < latihan/p04/q01_view_film_murah.sql
CREATE VIEW

Alasan :
Perintah ini berfungsi untuk membuat view fasad (tabel virtual) bernama lab4.film_murah yang menyaring data film dengan harga sewa rental_rate <= 0.99. Tanpa adanya CHECK OPTION, view ini bertindak sebagai jendela filter yang memperbolehkan operasi tulis ke tabel dasar tanpa memvalidasi apakah data baru tersebut benar-benar memenuhi kriteria WHERE.


### Q2
Perintah :
-- Diminta: menyisipkan satu film melalui view lab4.film_murah dengan rental_rate = 4.99, menghitung jumlah baris dengan judul yang sama di view dan tabel dasar, lalu menjelaskan selisihnya.
-- Dipilih: Melakukan INSERT melalui view tanpa check option dilanjutkan dengan query UNION ALL untuk menghitung baris di view dan tabel dasar agar silent filtering terlihat jelas.
-- Alternatif: Melakukan INSERT langsung ke tabel dasar; tidak dipilih karena tidak menguji perilaku mutasi data melalui view fasad.

INSERT INTO lab4.film_murah (title, rental_rate, rating)
VALUES ('Film Gaib Q2', 4.99, 'PG');

SELECT 'Di View' AS lokasi, count(*) FROM lab4.film_murah WHERE title = 'Film Gaib Q2'
UNION ALL
SELECT 'Di Tabel Dasar' AS lokasi, count(*) FROM lab4.film WHERE title = 'Film Gaib Q2';

Keluaran :
AGNES@LAPTOP-1T3ANVB7 MINGW64 ~/msbd-2026 (latihan/p04-sql2)
$ docker exec -i msbd-pg psql -U msbd -d latihan < latihan/p04/q02_baris_menghilang.sql
INSERT 0 1
     lokasi     | count 
----------------+-------
 Di View        |     0
 Di Tabel Dasar |     2
(2 rows)

Alasan :
Terjadi silent filtering. Baris data dengan harga 4.99 berhasil masuk dan tersimpan secara fisik di dalam tabel dasar (lab4.film), namun langsung disaring keluar oleh kondisi WHERE pada view. Akibatnya, saat dicek melalui view, jumlah barisnya 0, sementara di tabel dasar data tersebut benar-benar ada. Hal ini berbahaya karena operasi insert tampak berhasil bagi aplikasi, padahal datanya tersembunyi dari view.


### Q3
Perintah :
-- Diminta: membuat ulang view lab4.film_murah dengan WITH CASCADED CHECK OPTION, mengulangi penyisipan data dengan rental_rate = 4.99, dan menyalin pesan galat secara utuh.
-- Dipilih: Menggunakan CREATE OR REPLACE VIEW ditambah klausa WITH CASCADED CHECK OPTION agar setiap data yang dimasukkan wajib lolos dari filter WHERE view.
-- Alternatif: Menggunakan WITH LOCAL CHECK OPTION; tidak dipilih karena untuk view tunggal tanpa view bertingkat, cascaded lebih aman untuk memastikan tidak ada celah aturan filter.

CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99
WITH CASCADED CHECK OPTION;

INSERT INTO lab4.film_murah (title, rental_rate, rating)
VALUES ('Film Ditolak Q3', 4.99, 'PG');

Keluaran :
AGNES@LAPTOP-1T3ANVB7 MINGW64 ~/msbd-2026 (latihan/p04-sql2)
$ docker exec -i msbd-pg psql -U msbd -d latihan < latihan/p04/q03_check_option.sql
CREATE VIEW
ERROR:  new row violates check option for view "film_murah"
DETAIL:  Failing row contains (6, Film Ditolak Q3, null, null, null, 3, 4.99, null, null, PG, 2026-09-14 13:33:37.564375).

Alasan :
Penambahan WITH CASCADED CHECK OPTION memaksa PostgreSQL untuk memvalidasi setiap operasi INSERT atau UPDATE agar harus selalu mematuhi kondisi saringan WHERE (rental_rate <= 0.99). Karena data yang dimasukkan memiliki rental_rate = 4.99, operasi langsung ditolak mentah-mentah oleh sistem dan memunculkan galat.


### Q4
Perintah :
-- Diminta: membuat view lab4.pendapatan_kategori yang menggunakan GROUP BY, mencoba menyisipkan data melaluinya, lalu menjelaskan alasan view tersebut tidak auto-updatable.
-- Dipilih: Membuat view dengan fungsi agregat count dan avg beserta GROUP BY rating untuk melihat pembatasan mutasi data pada view non-updatable.
-- Alternatif: Menggunakan view biasa tanpa agregasi; tidak dipilih karena tidak sesuai dengan soal yang menguji batasan view berbasis agregasi.

CREATE OR REPLACE VIEW lab4.pendapatan_kategori AS
SELECT rating, count(*) AS total_film, avg(rental_rate) AS rata_rental
FROM lab4.film
GROUP BY rating;

INSERT INTO lab4.pendapatan_kategori (rating, total_film, rata_rental)
VALUES ('NC-17', 10, 3.50);

Keluaran :
AGNES@LAPTOP-1T3ANVB7 MINGW64 ~/msbd-2026 (latihan/p04-sql2)
$ docker exec -i msbd-pg psql -U msbd -d latihan < latihan/p04/q04_view_pendapatan_kategori.sql
CREATE VIEW
ERROR:  cannot insert into view "pendapatan_kategori"
DETAIL:  Views containing GROUP BY are not automatically updatable.
HINT:  To enable inserting into the view, provide an INSTEAD OF INSERT trigger or an unconditional ON INSERT DO INSTEAD rule.

Alasan :
View yang mengandung fungsi agregat (count, avg) dan klausul pengelompokan (GROUP BY) bersifat not auto-updatable. PostgreSQL tidak memiliki mekanisme otomatis untuk memetakan kembali nilai agregat ke baris-baris data individual di dalam tabel dasar fisik, sehingga operasi INSERT ditolak kecuali jika dipasangkan dengan trigger khusus INSTEAD OF.


### Q5
-- Diminta: menjalankan query agregasi akses berdasarkan bulan dan kanal,
-- serta mencatat waktu eksekusinya.

-- Dipilih: date_trunc untuk mengelompokkan waktu menjadi bulan, COUNT(*)
-- untuk menghitung seluruh akses, dan COUNT(DISTINCT film_id) untuk
-- menghitung jumlah film unik pada setiap kombinasi bulan dan kanal.

-- Alternatif: GROUP BY EXTRACT(YEAR FROM waktu), EXTRACT(MONTH FROM waktu);
-- tidak dipilih karena date_trunc menghasilkan nilai periode bulan secara
-- langsung dan lebih sederhana digunakan sebagai satu kolom pengelompokan.

\timing on

SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2;

Keluaran:
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p04-sql2)
$ docker compose exec -T postgres psql -U msbd -d latihan   -f /dev/stdin < latihan/p04/q05_query_dasar_akses.sql
Timing is on.
         bulan          |  kanal  | jumlah_akses | film_unik 
------------------------+---------+--------------+-----------
 2025-09-01 00:00:00+00 | android |         6914 |       999
 2025-09-01 00:00:00+00 | ios     |         6691 |      1000
 2025-09-01 00:00:00+00 | kiosk   |         3447 |       967
 2025-09-01 00:00:00+00 | web     |         3320 |       968
 2025-10-01 00:00:00+00 | android |        14143 |      1000
 2025-10-01 00:00:00+00 | ios     |        14158 |      1000
 2025-10-01 00:00:00+00 | kiosk   |         7106 |       999
 2025-10-01 00:00:00+00 | web     |         7126 |      1000
 2025-11-01 00:00:00+00 | android |        13782 |      1000
 2025-11-01 00:00:00+00 | ios     |        13786 |      1000
 2025-11-01 00:00:00+00 | kiosk   |         6959 |      1000
 2025-11-01 00:00:00+00 | web     |         6779 |       996
 2025-12-01 00:00:00+00 | android |        14298 |      1000
 2025-12-01 00:00:00+00 | ios     |        14212 |      1000
 2025-12-01 00:00:00+00 | kiosk   |         7121 |      1000
 2025-12-01 00:00:00+00 | web     |         7105 |      1000
 2026-01-01 00:00:00+00 | android |        13846 |      1000
 2026-01-01 00:00:00+00 | ios     |        14175 |      1000
 2026-01-01 00:00:00+00 | kiosk   |         6948 |      1000
 2026-01-01 00:00:00+00 | web     |         7152 |      1000
 2026-02-01 00:00:00+00 | android |        12819 |      1000
 2026-02-01 00:00:00+00 | ios     |        12497 |      1000
 2026-02-01 00:00:00+00 | kiosk   |         6474 |      1000
 2026-02-01 00:00:00+00 | web     |         6291 |      1000
 2026-03-01 00:00:00+00 | android |        14148 |      1000
 2026-03-01 00:00:00+00 | ios     |        14124 |      1000
 2026-03-01 00:00:00+00 | kiosk   |         7162 |       999
 2026-03-01 00:00:00+00 | web     |         7030 |      1000
 2026-04-01 00:00:00+00 | android |        13789 |      1000
 2026-04-01 00:00:00+00 | ios     |        13485 |      1000
 2026-04-01 00:00:00+00 | kiosk   |         6690 |       999
 2026-04-01 00:00:00+00 | web     |         6958 |      1000
 2026-05-01 00:00:00+00 | android |        14247 |      1000
 2026-05-01 00:00:00+00 | ios     |        14164 |      1000
 2026-05-01 00:00:00+00 | kiosk   |         7009 |       999
 2026-05-01 00:00:00+00 | web     |         7064 |       999
 2026-06-01 00:00:00+00 | android |        13677 |      1000
 2026-06-01 00:00:00+00 | ios     |        13665 |      1000
 2026-06-01 00:00:00+00 | kiosk   |         6895 |       999
 2026-06-01 00:00:00+00 | web     |         6880 |       996
 2026-07-01 00:00:00+00 | android |        14275 |      1000
 2026-07-01 00:00:00+00 | ios     |        14033 |      1000
 2026-07-01 00:00:00+00 | kiosk   |         7132 |       999
 2026-07-01 00:00:00+00 | web     |         7228 |       999
 2026-08-01 00:00:00+00 | android |        14214 |      1000
 2026-08-01 00:00:00+00 | ios     |        14140 |      1000
 2026-08-01 00:00:00+00 | kiosk   |         7083 |      1000
 2026-08-01 00:00:00+00 | web     |         7123 |      1000
 2026-09-01 00:00:00+00 | android |         6819 |       999
 2026-09-01 00:00:00+00 | ios     |         6961 |       999
 2026-09-01 00:00:00+00 | kiosk   |         3442 |       967
 2026-09-01 00:00:00+00 | web     |         3414 |       969
(52 rows)

Time: 618.533 ms

Alasan:
Hasil Q5 menghasilkan 52 baris karena data akses tersebar pada 13 bulan kalender dan terdapat 4 kanal akses, sehingga terbentuk 13 × 4 = 52 kombinasi kelompok. Jumlah akses pada setiap kelompok berbeda karena data waktu dan kanal dibuat menggunakan nilai acak. Nilai film_unik hampir selalu mendekati 1.000 karena film_id dihasilkan secara acak pada rentang 1 sampai 1.000 dan jumlah transaksi pada setiap kelompok cukup besar sehingga hampir seluruh film muncul. Jumlah akses pada September 2025 dan September 2026 lebih sedikit karena kedua bulan tersebut hanya terwakili sebagian dalam rentang 365 hari saat data dibuat. Query membutuhkan waktu 618,533 ms pada lingkungan PostgreSQL yang digunakan.


### Q6
-- Diminta: menjadikan query Q5 sebagai materialized view dengan WITH NO DATA,
-- membuktikan bahwa matview belum dapat dibaca sebelum refresh, kemudian
-- melakukan refresh biasa dan mencatat waktunya.

-- Dipilih: CREATE MATERIALIZED VIEW ... WITH NO DATA agar materialized view
-- dibuat terlebih dahulu tanpa mengisi hasil query, kemudian REFRESH MATERIALIZED
-- VIEW digunakan untuk mengisi hasil agregasinya.

-- Alternatif: CREATE MATERIALIZED VIEW tanpa WITH NO DATA; tidak dipilih karena
-- soal secara khusus meminta kondisi awal matview kosong sebelum dilakukan refresh.

\timing on

CREATE MATERIALIZED VIEW lab4.ringkasan_akses AS
SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2
WITH NO DATA;

-- Coba membaca materialized view sebelum refresh.
SELECT *
FROM lab4.ringkasan_akses;

-- Isi materialized view dengan hasil query.
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;

Keluaran:
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p04-sql2)
$ docker compose exec -T postgres psql -U msbd -d latihan   -f /dev/stdin < latihan/p04/q06_buat_matview.sql
Timing is on.
CREATE MATERIALIZED VIEW
Time: 6.504 ms
Time: 0.398 ms
psql:/proc/self/fd/0:26: ERROR:  materialized view "ringkasan_akses" has not been populated
HINT:  Use the REFRESH MATERIALIZED VIEW command.
REFRESH MATERIALIZED VIEW
Time: 646.175 ms

Alasan:
Materialized view lab4.ringkasan_akses berhasil dibuat menggunakan WITH NO DATA. Ketika materialized view tersebut dibaca sebelum dilakukan refresh, PostgreSQL menghasilkan error materialized view "ringkasan_akses" has not been populated. Setelah itu, REFRESH MATERIALIZED VIEW berhasil dijalankan dengan waktu 646.175 ms.


### Q7
-- Diminta: mencoba refresh materialized view secara concurrent, mencatat
-- pesan galat, membuat unique index yang mencakup seluruh baris matview,
-- kemudian mengulangi refresh concurrent dan mencatat waktunya.

-- Dipilih: unique index pada (bulan, kanal) karena kombinasi tersebut
-- mengidentifikasi setiap baris hasil GROUP BY pada materialized view.
-- REFRESH CONCURRENTLY dipilih untuk memungkinkan pembaca tetap mengakses
-- materialized view selama proses refresh.

-- Alternatif: menggunakan REFRESH MATERIALIZED VIEW biasa saja; tidak dipilih
-- karena refresh biasa dapat memblokir pembaca dan tidak menguji tujuan
-- utama penggunaan CONCURRENTLY.

\timing on

-- Percobaan pertama: seharusnya gagal karena belum ada unique index.
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- Membuat unique index untuk memenuhi syarat refresh concurrent.
CREATE UNIQUE INDEX ringkasan_akses_bulan_kanal_uidx
ON lab4.ringkasan_akses (bulan, kanal);

-- Percobaan kedua: refresh concurrent setelah unique index dibuat.
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

Keluaran:
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p04-sql2)
$ docker compose exec -T postgres psql -U msbd -d latihan   -f /dev/stdin < latihan/p04/q07_refresh_concurrently.sql
Timing is on.
psql:/proc/self/fd/0:17: ERROR:  cannot refresh materialized view "lab4.ringkasan_akses" concurrently
HINT:  Create a unique index with no WHERE clause on one or more columns of the materialized view.
Time: 1.170 ms
CREATE INDEX
Time: 4.578 ms
REFRESH MATERIALIZED VIEW
Time: 609.347 ms

Alasan:
Percobaan menunjukkan bahwa REFRESH MATERIALIZED VIEW CONCURRENTLY memiliki persyaratan berupa unique index tanpa klausa WHERE pada materialized view. Percobaan pertama gagal dengan waktu 1.170 ms karena ringkasan_akses belum memiliki unique index. Setelah unique index pada (bulan, kanal) dibuat dengan waktu 4.578 ms, percobaan kedua berhasil melakukan refresh concurrent dengan waktu 609.347 ms. Dengan demikian, unique index diperlukan agar PostgreSQL dapat melakukan pembaruan materialized view secara concurrent.


### Q8
-- Diminta: membuktikan bahwa REFRESH MATERIALIZED VIEW CONCURRENTLY tidak
-- memblokir pembaca, kemudian membandingkannya dengan refresh biasa.

-- Dipilih: dua sesi PostgreSQL digunakan agar SELECT pada sesi 2 dapat
-- dijalankan ketika refresh pada sesi 1 sedang berlangsung. Perbandingan
-- dilakukan antara REFRESH CONCURRENTLY dan REFRESH biasa untuk melihat
-- perbedaan perilaku lock terhadap pembaca.

-- Alternatif: menjalankan refresh dan SELECT secara berurutan dalam satu sesi;
-- tidak dipilih karena tidak dapat membuktikan apakah pembaca terblokir selama
-- proses refresh berlangsung.

-- ============================================================
-- SESI 1
-- ============================================================

INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1,
       now(),
       'web'
FROM generate_series(1, 200000);

-- Refresh concurrent.
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;


-- ============================================================
-- SESI 2
-- Jalankan segera setelah refresh pada sesi 1 dimulai.
-- ============================================================

SELECT count(*)
FROM lab4.ringkasan_akses;

Keluaran:
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p04-sql2)
$ docker compose exec -T postgres psql -U msbd -d latihan   -f /dev/stdin < latihan/p04/q08_buktikan_pembaca.sql
INSERT 0 200000
REFRESH MATERIALIZED VIEW
 count 
-------
    52
(1 row)

### Q9
### Q10
### Q11
### Q12
### Q13
### Q14
### Q15


### Q16
#### 1. NO ACTION
Perintah:
CREATE TABLE lab4.ulasan_no_action (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    isi_ulasan text,
    CONSTRAINT fk_ulasan_film_no_action
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE NO ACTION
);

INSERT INTO lab4.ulasan_no_action (film_id, isi_ulasan)
VALUES (1, 'Film bagus');

DELETE FROM lab4.film
WHERE film_id = 1;

Keluaran:
INSERT 0 1
ERROR: update or delete on table "film" violates foreign key constraint
"fk_ulasan_film_no_action" on table "ulasan_no_action"
DETAIL: Key (film_id)=(1) is still referenced from table "ulasan_no_action".

Alasan:
Penghapusan film ditolak karena film_id = 1 masih digunakan oleh tabel ulasan_no_action. Pada NO ACTION, data induk tidak dapat dihapus apabila masih terdapat data anak yang mereferensikannya.

#### 2. CASCADE
Perintah:
CREATE TABLE lab4.ulasan_cascade (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    isi_ulasan text,
    CONSTRAINT fk_ulasan_film_cascade
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE CASCADE
);

INSERT INTO lab4.ulasan_cascade (film_id, isi_ulasan)
VALUES (2, 'Film sangat menarik');

SELECT *
FROM lab4.ulasan_cascade
WHERE film_id = 2;

DELETE FROM lab4.film
WHERE film_id = 2;

SELECT *
FROM lab4.ulasan_cascade
WHERE film_id = 2;

Keluaran:
INSERT 0 1

ulasan_id | film_id |     isi_ulasan
-----------+---------+---------------------
1          | 2       | Film sangat menarik

DELETE 1

ulasan_id | film_id | isi_ulasan
-----------+----------+------------
(0 rows)

Alasan:
Ketika film_id = 2 dihapus dari tabel film, data ulasan yang memiliki film_id = 2 juga otomatis dihapus. Hal tersebut menunjukkan bahwa ON DELETE CASCADE meneruskan penghapusan dari tabel induk ke tabel anak.

#### 3. SET NULL
Perintah:
CREATE TABLE lab4.ulasan_set_null (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer,
    isi_ulasan text,
    CONSTRAINT fk_ulasan_film_set_null
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE SET NULL
);

INSERT INTO lab4.ulasan_set_null (film_id, isi_ulasan)
VALUES (3, 'Film cukup bagus');

SELECT *
FROM lab4.ulasan_set_null
WHERE film_id = 3;

DELETE FROM lab4.film
WHERE film_id = 3;

SELECT *
FROM lab4.ulasan_set_null
WHERE ulasan_id = 1;

Keluaran:

INSERT 0 1

ulasan_id | film_id |    isi_ulasan
-----------+---------+------------------
1          | 3       | Film cukup bagus

DELETE 1

ulasan_id | film_id |    isi_ulasan
-----------+----------+------------------
1          | NULL    | Film cukup bagus

Alasan:
Data film berhasil dihapus, tetapi data ulasan tetap dipertahankan. Nilai film_id pada ulasan berubah menjadi NULL. Hal ini menunjukkan bahwa ON DELETE SET NULL memutus hubungan dengan data induk tanpa menghapus data anak.

### Q17 
Membuat tabel harga film

Perintah:
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    CONSTRAINT exclude_harga_film
        EXCLUDE USING gist (
            film_id WITH =,
            wilayah WITH =,
            berlaku WITH &&
        )
);

Keluaran:
CREATE EXTENSION
CREATE TABLE

Alasan:
Extension btree_gist digunakan agar operator = dapat digunakan pada kolom dalam constraint EXCLUDE. Constraint tersebut memastikan kombinasi film_id, wilayah, dan periode berlaku tidak memiliki periode yang saling tumpang tindih.

INSERT diterima

Perintah:
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (1, 'Indonesia', 25.00, '[2026-01-01,2026-04-01)');

Keluaran:
INSERT 0 1

Alasan:
Data berhasil dimasukkan karena belum terdapat data dengan film dan wilayah yang sama pada periode yang tumpang tindih.

INSERT ditolak

Perintah:
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (1, 'Indonesia', 30.00, '[2026-03-01,2026-06-01)');

Keluaran:
ERROR: conflicting key value violates exclusion constraint
"exclude_harga_film"

Alasan:
INSERT ditolak karena film_id = 1 dan wilayah Indonesia sama dengan data sebelumnya, sementara periode 2026-03-01 sampai 2026-06-01 tumpang tindih dengan periode 2026-01-01 sampai 2026-04-01.


### Q18
```sql
-- Diminta: Membuat fase expand dengan struktur harga baru dan trigger tulis ganda agar perubahan rental_rate pada bentuk lama tercermin pada bentuk baru.

-- Dipilih: Menggunakan trigger AFTER UPDATE pada lab4.film untuk menyinkronkan perubahan rental_rate ke lab4.harga_film, sehingga bentuk lama tetap dapat dibaca selama proses migrasi.

-- Alternatif: Melakukan sinkronisasi harga secara manual setelah setiap perubahan; tidak dipilih karena perubahan dapat terlewat dan data pada bentuk baru tidak selalu terbarui.

SET search_path = lab4, public;

-- =========================================================
-- 1. BUAT STRUKTUR BARU
-- =========================================================

DROP TABLE IF EXISTS lab4.harga_film CASCADE;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    CONSTRAINT exclude_harga_film
        EXCLUDE USING gist (
            film_id WITH =,
            wilayah WITH =,
            berlaku WITH &&
        )
);

-- =========================================================
-- 2. PASANG TULIS GANDA
-- =========================================================

CREATE OR REPLACE FUNCTION lab4.sinkronisasi_harga_film()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE lab4.harga_film
    SET harga = NEW.rental_rate
    WHERE film_id = NEW.film_id
      AND wilayah = 'Indonesia'
      AND upper_inf(berlaku);

    IF NOT FOUND THEN
        INSERT INTO lab4.harga_film
            (film_id, wilayah, harga, berlaku)
        VALUES
            (
                NEW.film_id,
                'Indonesia',
                NEW.rental_rate,
                daterange(CURRENT_DATE, NULL, '[)')
            );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sinkronisasi_harga_film
ON lab4.film;

CREATE TRIGGER trg_sinkronisasi_harga_film
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
EXECUTE FUNCTION lab4.sinkronisasi_harga_film();

-- =========================================================
-- 3. BACKFILL
-- =========================================================

INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
SELECT
    film_id,
    'Indonesia',
    rental_rate,
    daterange(CURRENT_DATE, NULL, '[)')
FROM lab4.film;

-- =========================================================
-- 4. VERIFIKASI
-- =========================================================

-- Melihat data harga setelah backfill
SELECT
    f.film_id,
    f.title,
    f.rental_rate,
    h.wilayah,
    h.harga,
    h.berlaku
FROM lab4.film f
JOIN lab4.harga_film h
    ON f.film_id = h.film_id
ORDER BY f.film_id;

-- Mengubah rental_rate pada bentuk lama
UPDATE lab4.film
SET rental_rate = rental_rate + 1.00
WHERE film_id = 1;

-- Memastikan perubahan tercermin pada bentuk baru
SELECT
    f.title,
    f.rental_rate,
    h.harga
FROM lab4.film f
JOIN lab4.harga_film h
    ON f.film_id = h.film_id
WHERE f.film_id = 1;

-- =========================================================
-- 5. VIEW FASAD
-- =========================================================

CREATE OR REPLACE VIEW lab4.film_harga AS
SELECT
    f.film_id,
    f.title,
    h.harga AS rental_rate,
    h.wilayah,
    h.berlaku
FROM lab4.film f
JOIN lab4.harga_film h
    ON f.film_id = h.film_id;

-- Menguji view fasad
SELECT *
FROM lab4.film_harga
ORDER BY film_id;

-- =========================================================
-- 6. DROP BENTUK LAMA
-- =========================================================

-- Bentuk lama tidak langsung dihapus karena sesi pembaca
-- masih menggunakan lab4.film selama proses migrasi.
-- Setelah sesi pembaca selesai, bentuk lama dapat dihapus
-- dengan perintah berikut:

-- DROP TABLE lab4.film;
```

### Q19
### Q20
### Q21



## Refleksi A–E

Pertanyaan Reflektif A
Sebuah tim menempatkan seluruh akses aplikasi melalui view dengan alasan lebih aman dan lebih rapi. Sebutkan dua keuntungan, dua kerugian, dan satu keadaan konkret ketika pendekatan ini justru mempersulit tim berdasarkan pengamatan Q1–Q4.
> Dua Keuntungan :
- Enkapsulasi Struktur Data (Keamanan Akses): Aplikasi atau pengguna luar cukup mengakses view tanpa perlu tahu struktur tabel asli di balik layar, sehingga kolom sensitif atau tidak relevan bisa disembunyikan.

- Sentralisasi Validasi Bisnis (CHECK OPTION): Aturan validasi (seperti batasan harga sewa) dapat dikunci langsung pada view menggunakan CHECK OPTION agar data yang masuk ke tabel dasar selalu konsisten dengan aturan bisnis tanpa harus menulis ulang kode validasi di setiap aplikasi klien.

Dua Kerugian
- Risiko Silent Filtering: Tanpa konfigurasi pengaman yang tepat (seperti CHECK OPTION), insert data bisa berhasil disimpan secara fisik ke tabel dasar tanpa masuk ke kriteria view, yang mengecoh aplikasi dan menyulitkan pelacakan data hilang.

- Pembatasan Mutasi Data (Non-Updatable View): Penggunaan fungsi agregat atau grouping (GROUP BY) membuat view kehilangan kemampuan auto-updatable, sehingga operasi tulis seperti insert atau update langsung ditolak dan membutuhkan trigger tambahan yang lebih kompleks.

Keadaan Konkret yang Mempersulit
Pendekatan ini justru mempersulit tim saat aplikasi melakukan debugging atau bulk insert data historis yang bervariasi nilainya. Misalnya, ketika tim melakukan migrasi data massal atau form input admin memasukkan produk dengan harga khusus di luar batas standar view tanpa menyadari adanya batasan CHECK OPTION, aplikasi akan mendadak crash atau memunculkan galat violation check option yang membingungkan karena mereka mengira data dimasukkan ke tabel yang benar, padahal terbentur aturan fasad view.

Pertanyaan Reflektif B
Materialized view memberikan waktu baca yang cepat karena hasil agregasi sudah disimpan secara fisik. Namun, data di dalamnya tidak otomatis berubah ketika tabel sumber berubah. Semakin lama interval refresh, semakin besar kemungkinan laporan menampilkan data yang sudah tidak mutakhir. Sebaliknya, semakin sering materialized view di-refresh, semakin besar beban komputasi yang diberikan kepada database. REFRESH CONCURRENTLY mengurangi gangguan terhadap pembaca, tetapi membutuhkan unique index dan umumnya memiliki pekerjaan tambahan dibandingkan refresh biasa.

Sebagai kompromi konkret, laporan keuangan dapat menetapkan batas kebasian maksimal 15 menit. Materialized view dijadwalkan melakukan refresh setiap 10 menit, sehingga dalam kondisi normal data yang ditampilkan tidak lebih tua dari batas yang ditentukan. Penggunaan REFRESH MATERIALIZED VIEW CONCURRENTLY memungkinkan laporan tetap dapat dibaca ketika proses refresh berlangsung, sehingga kecepatan akses dan ketersediaan laporan tetap terjaga.

Apabila refresh gagal di tengah proses, sistem sebaiknya tidak menghapus atau mengganti hasil refresh terakhir yang berhasil. Versi materialized view terakhir tetap digunakan sebagai data laporan, sementara kegagalan dicatat dalam log dan administrator diberi peringatan. Sistem kemudian dapat melakukan retry terbatas atau mencoba kembali pada jadwal refresh berikutnya. Dengan cara ini, kegagalan refresh tidak langsung membuat laporan menjadi tidak tersedia.