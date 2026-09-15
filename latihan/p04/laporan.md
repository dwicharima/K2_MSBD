# Laporan Latihan Kelompok Pertemuan 4

| Nama | NIM | Kontribusi |
|------|-----|------------|
| Rasyd Arija Azron Ritonga | 251402020 |  |
| Fakhry Adrian Daulay | 251402053 |  |
| Dwi Charima Husni | 251402088 |  |
| Agnes Natalia Br Siregar| 251402108 |  |
| Abdullah Zufar Aulia Nasution | 251402111 |  |

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