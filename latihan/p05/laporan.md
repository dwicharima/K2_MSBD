# Laporan Latihan Kelompok Pertemuan 5

| Nama | NIM | Kontribusi |
|------|-----|------------|
| Agnes Natalia Siregar | 251402108 | Q1-Q4, refleksi A |
| Fakhry Adrian Daulay | 251402053 |  | 
| Rasyd Arija A. Ritonga |251402020 |  | 
| Dwi Charima Husni | 251402088 |  |
| Abdullah Zufar Aulia | 251402111 |  |

### Q1

**Perintah :**
-- Diminta: menulis function lab5.total_dibayar(p_rental_id bigint) untuk menghitung total pembayaran suatu penyewaan.
-- Dipilih: menggunakan fungsi SQL STABLE dengan coalesce untuk menangani nilai null.
-- Alternatif: prosedur PL/pgSQL; tidak dipilih karena fungsi SQL lebih ringkas dan efisien untuk query tunggal.

CREATE OR REPLACE FUNCTION lab5.total_dibayar(p_rental_id bigint)
RETURNS numeric LANGUAGE sql STABLE AS $$
SELECT coalesce(sum(amount), 0) FROM lab5.payment_tx WHERE rental_id = p_rental_id;
$$;

**Keluaran :**
AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026 (latihan/p05)
$ python -c 'import psycopg; conn = psycopg.connect("postgresql://msbd:msbd2026@localhost:5432/pagila"); cur = conn.cursor(); cur.execute(open("latihan/p05/q01_total_dibayar.sql", "r", encoding="utf-8").read()); conn.commit(); cur.execute("SELECT lab5.total_dibayar(1);"); print("Hasil Q1:", cur.fetchall())'
Hasil Q1: [(Decimal('25.00'),)]
(.venv) 

**Alasan :**
Perintah ini Untuk menghitung dan menjumlahkan total nominal pembayaran (amount) yang masuk pada tabel transaksi pembayaran (lab5.payment_tx), guna memastikan bahwa seluruh data finansial dari aktivitas rental yang diproses terekam dan teragregasi secara akurat.


### Q2 

**Perintah :**
-- Diminta: menulis prosedur lab5.process_rental untuk memproses penyewaan baru dan mencatat pembayarannya secara transaksional.
-- Dipilih: menggunakan prosedur PL/pgSQL dengan blok transaksi eksplisit dan penanganan parameter input.
-- Alternatif: fungsi SQL biasa; tidak dipilih karena proses penyewaan melibatkan operasi INSERT multitabel dan manajemen transaksi (commit/rollback).

CREATE OR REPLACE PROCEDURE lab5.process_rental(
  IN p_customer_id  integer,
  IN p_inventory_id integer,
  IN p_staff_id     integer,
  IN p_amount       numeric(10,2),
  IN p_metadata     jsonb DEFAULT '{}'::jsonb,
  INOUT p_rental_id bigint DEFAULT NULL
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'nilai pembayaran harus positif, diterima %', p_amount
      USING ERRCODE = '22003';   -- numeric_value_out_of_range
  END IF;
  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id, metadata)
  VALUES (p_customer_id, p_inventory_id, p_staff_id,
          coalesce(p_metadata, '{}'::jsonb))
  RETURNING rental_id INTO p_rental_id;
  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (p_rental_id, p_amount);
  -- sengaja tidak ada COMMIT: batas transaksi milik pemanggil
END;
$$;

**Keluaran :**
AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026 (latihan/p05)
$ python -c 'import psycopg; conn = psycopg.connect("postgresql://msbd:msbd2026@localhost:5432/pagila"); cur = conn.cursor(); cur.execute("SELECT * FROM lab5.rental_tx;"); print("rental_tx:", cur.fetchall()); cur.execute("SELECT * FROM lab5.payment_tx;"); print("payment_tx:", cur.fetchall())'
rental_tx: [(1, 1, 1, 1, 'ACTIVE', [], {}, datetime.datetime(2026, 9, 21, 12, 53, 22, 191520, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC')))]
payment_tx: [(1, 1, Decimal('25.00'), datetime.datetime(2026, 9, 21, 12, 53, 22, 191520, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC')))]
(.venv) 

**Alasan :**
Perintah untuk mengeksekusi proses penyewaan dan pembayaran secara atomik (satu kesatuan). Artinya, data penyewaan (rental_tx) dan pembayaran (payment_tx) harus berhasil disimpan secara bersamaan. Jika salah satu gagal, seluruh perubahan dibatalkan (rollback) untuk mencegah terjadinya data yang tidak konsisten atau menggantung.


### Q3 

**Perintah :**
-- Diminta: Membuktikan rollback transaksi saat p_amount bernilai negatif pada lab5.process_rental.
-- Dipilih: Melakukan pemanggilan dengan nilai negatif, menyalin galat, dan menghitung jumlah baris rental_tx.
-- Alternatif: Menggunakan try-catch blok di PL/pgSQL; tidak dipilih karena langsung diuji lewat eksekusi luar.

-- Pemanggilan yang memicu galat (amount negatif -4.99)
CALL lab5.process_rental(
    p_customer_id := 1,
    p_inventory_id := 1,
    p_staff_id := 1,
    p_amount := -4.99
);

-- Menghitung jumlah data setelah rollback terjadi
SELECT count(*) AS jumlah_rental FROM lab5.rental_tx;

** Keluaran : **
AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026 (latihan/p05)
$ python -c 'import psycopg; conn = psycopg.connect("postgresql://msbd:msbd2026@localhost:5432/pagila"); cur = conn.cursor()
try:
    cur.execute("CALL lab5.process_rental(1, 1, 1, -4.99);")
except Exception as e:
    print("Galat:", e)
    conn.rollback()
cur.execute("SELECT count(*) FROM lab5.rental_tx;")
print("Jumlah rental:", cur.fetchone()[0])'
Galat: nilai pembayaran harus positif, diterima -4.99
CONTEXT:  PL/pgSQL function lab5.process_rental(integer,integer,integer,numeric,jsonb,bigint) line 4 at RAISE
Jumlah rental: 1
(.venv) 

** Alasan & Penjelasan Mengapa Jumlahnya Tidak Bertambah : **
Karena di dalam prosedur lab5.process_rental terdapat validasi IF p_amount <= 0. Ketika nilai -4.99 dimasukkan, kondisi tersebut terpenuhi dan langsung memicu exception yang menghentikan jalannya eksekusi sebelum perintah INSERT ke tabel rental_tx dan payment_tx dijalankan.

Akibat sifat atomik transaksi basis data, seluruh perubahan yang sempat terjadi di dalam blok transaksi tersebut langsung dibatalkan (rollback). Oleh karena itu, jumlah baris pada lab5.rental_tx tidak bertambah (tetap seperti semula) karena tidak ada data baru yang berhasil disimpan.


### Q4

** Perintah : **
-- Diminta: Membuat salinan procedure yang menjalankan COMMIT di tengah eksekusi (setelah insert pertama).
-- Dipilih: Menggunakan CREATE OR REPLACE PROCEDURE dengan menyisipkan COMMIT di antara INSERT rental_tx dan payment_tx.
-- Alternatif: Tanpa COMMIT; tidak dipilih karena tujuan soal adalah mendemonstrasikan galat transaksi.

CREATE OR REPLACE PROCEDURE lab5.process_rental_with_commit(
  IN p_customer_id  integer,
  IN p_inventory_id integer,
  IN p_staff_id     integer,
  IN p_amount       numeric(10,2),
  IN p_metadata     jsonb DEFAULT '{}'::jsonb,
  INOUT p_rental_id bigint DEFAULT NULL
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'nilai pembayaran harus positif, diterima %', p_amount
      USING ERRCODE = '22003';
  END IF;

  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id, metadata)
  VALUES (p_customer_id, p_inventory_id, p_staff_id,
          coalesce(p_metadata, '{}'::jsonb))
  RETURNING rental_id INTO p_rental_id;

  -- Sengaja menyisipkan COMMIT di tengah procedure
  COMMIT;

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (p_rental_id, p_amount);
END;
$$;


** Keluaran : **
AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026 (latihan/p05)
$ python -c 'import psycopg
try:
    with psycopg.connect("postgresql://msbd:msbd2026@localhost:5432/pagila") as conn:
        with conn.cursor() as cur:
            cur.execute("CALL lab5.process_rental_with_commit(1, 1, 1, 50.00);")
except Exception as e:
    print("Galat:", e)'
Galat: invalid transaction termination
CONTEXT:  PL/pgSQL function lab5.process_rental_with_commit(integer,integer,integer,numeric,jsonb,bigint) line 14 at COMMIT
(.venv) 

** Alasan : **
PostgreSQL melarang adanya perintah COMMIT atau ROLLBACK di dalam prosedur PL/pgSQL jika prosedur tersebut dipanggil dari dalam blok transaksi eksternal (seperti koneksi Python with psycopg.connect()). Manajemen transaksi sepenuhnya dipegang oleh aplikasi pemanggil di luar, sehingga prosedur tidak boleh mengatur akhir transaksinya sendiri untuk mencegah inkonsistensi sistem basis data.


### Q5

** Perintah : **
-- Diminta: Menangkap galat foreign_key_violation dan memberikan pesan ramah.
-- Dipilih: Blok EXCEPTION WHEN foreign_key_violation di dalam PL/pgSQL.
-- Alternatif: Validasi manual SELECT COUNT(*) sebelum INSERT; tidak dipilih karena memicu race condition.

CREATE OR REPLACE PROCEDURE lab5.process_rental_safe(
  p_customer_id integer,
  p_inventory_id integer,
  p_staff_id integer,
  p_amount numeric
)
LANGUAGE plpgsql AS $$
DECLARE
  v_rental_id bigint;
BEGIN
  -- Insert ke rental_tx
  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id)
  VALUES (p_customer_id, p_inventory_id, p_staff_id)
  RETURNING rental_id INTO v_rental_id;

  -- Insert ke payment_tx
  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (v_rental_id, p_amount);

EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'Gagal memproses penyewaan: Pelanggan, inventaris, atau staf tidak ditemukan.'
      USING HINT = 'Pastikan customer_id, inventory_id, dan staff_id yang dimasukkan valid.',
            ERRCODE = 'foreign_key_violation';
END;
$$;

** Keluaran : **
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p05)
$ python -c "
import psycopg
conn = psycopg.connect('postgresql://msbd:msbd2026@localhost:5432/pagila')
cur = conn.cursor()

cur.execute(open('latihan/p05/q05_exception_fk.sql', 'r', encoding='utf-8').read())
conn.commit()

try:
    cur.execute('CALL lab5.process_rental_safe(99999, 1, 1, 15.00);')
    conn.commit()
except psycopg.Error as e:
    print('ERROR:', e)
    print('SQLSTATE:', e.sqlstate)
"
ERROR: Gagal memproses penyewaan: Pelanggan, inventaris, atau staf tidak ditemukan.
HINT: Pastikan customer_id, inventory_id, dan staff_id yang dimasukkan valid.

SQLSTATE: 23503

** Alasan : **
Saat customer_id bernilai 99999 dimasukkan, PostgreSQL mendeteksi bahwa ID tersebut tidak ada pada tabel acuan (public.customer). Blok EXCEPTION WHEN foreign_key_violation memotong galat mentah bawaan (default constraints error) dan menghentikan transaksi, lalu menggantikannya dengan pesan kustom melalui RAISE EXCEPTION. Tipe galatnya tetap berada di kelas foreign_key_violation sehingga SQLSTATE yang diterima oleh psycopg tetap bernilai 23503.


### Q6

** Perintah : **
-- Diminta: memasukkan nilai nol dan negatif ke lab5.payment_tx untuk menguji domain positive_amount.
-- Dipilih: dua statement INSERT terpisah untuk merekam galat masing-masing batas nilai secara presisi.
-- Alternatif: satu INSERT dengan multiple values; tidak dipilih karena eksekusi terhenti pada galat pertama.

-- 1. Uji nilai nol (0.00)
INSERT INTO lab5.payment_tx (rental_id, amount) 
VALUES (1, 0.00);

-- Galat yang dihasilkan:
-- ERROR:  value for domain lab5.positive_amount violates check constraint "positive_amount_check"
-- SQLSTATE: 23514

-- 2. Uji nilai negatif (-15.50)
INSERT INTO lab5.payment_tx (rental_id, amount) 
VALUES (1, -15.50);

-- Galat yang dihasilkan:
-- ERROR:  value for domain lab5.positive_amount violates check constraint "positive_amount_check"
-- SQLSTATE: 23514

** Keluaran : **
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p05)
$ python -c "
import psycopg
conn = psycopg.connect('postgresql://msbd:msbd2026@localhost:5432/pagila')
cur = conn.cursor()
try:
    cur.execute(open('latihan/p05/q06_domain_positive_amount.sql', 'r', encoding='utf-8').read())
    conn.commit()
except psycopg.Error as e:
    print('ERROR', e)
    print('SQLSTATE:', e.sqlstate)
"
ERROR: value for domain lab5.positive_amount violates check constraint "positive_amount_check"
SQLSTATE: 23514

**Alasan :**
Domain lab5.positive_amount didefinisikan dengan klausa aturan CHECK (VALUE > 0). Ketika nilai 0.00 atau -15.50 dimasukkan ke dalam kolom bertipe domain tersebut, mesin PostgreSQL melakukan validasi tipe data di tingkat skema sebelum data ditulis ke disk. Karena nilai tersebut melanggar batasan > 0, transaksi langsung dibatalkan (abort) dan melempar SQLSTATE 23514.


### Q7

** Perintah : **
-- Diminta: menguji penambahan status 'EXPIRED' pada ENUM lab5.rental_status dan perilakunya.
-- Dipilih: penggunaan ALTER TYPE ... ADD VALUE untuk memperluas definisi ENUM secara aman.
-- Alternatif: mengubah kolom menjadi VARCHAR; tidak dipilih karena menghilangkan validasi ketat tingkat basis data.

-- 1. Coba set status ke 'EXPIRED' sebelum diperbarui
UPDATE lab5.rental_tx 
SET status = 'EXPIRED' 
WHERE rental_id = 1;

-- Galat yang dihasilkan:
-- ERROR:  invalid input value for enum lab5.rental_status: "EXPIRED"
-- SQLSTATE: 22P02

-- 2. Tambahkan nilai 'EXPIRED' ke dalam ENUM
ALTER TYPE lab5.rental_status ADD VALUE 'EXPIRED';

-- 3. Ulangi percobaan pembaruan status
UPDATE lab5.rental_tx 
SET status = 'EXPIRED' 
WHERE rental_id = 1;

-- Hasil:
-- UPDATE 1 (Berhasil diperbarui tanpa galat)

** Keluaran : **
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p05)
$ python -c "
import psycopg
conn = psycopg.connect('postgresql://msbd:msbd2026@localhost:5432/pagila')
cur = conn.cursor()
try:
    cur.execute(\"UPDATE lab5.rental_tx SET status = 'EXPIRED' WHERE rental_id = 1;\")
except psycopg.Error as e:
    print('ERROR sebelum ALTER:', e)
    print('SQLSTATE:', e.sqlstate)
conn.rollback()
cur.execute(\"ALTER TYPE lab5.rental_status ADD VALUE 'EXPIRED';\")
conn.commit()
cur.execute(\"UPDATE lab5.rental_tx SET status = 'EXPIRED' WHERE rental_id = 1;\")
conn.commit()
print('Berhasil UPDATE setelah ALTER TYPE')
"
ERROR sebelum ALTER: invalid input value for enum lab5.rental_status: "EXPIRED"
SQLSTATE: 22P02
Berhasil UPDATE setelah ALTER TYPE

** Alasan : **
Tipe data lab5.rental_status bersifat tertutup (strongly typed) dan hanya menerima nilai yang sudah terdaftar ('ACTIVE', 'RETURNED', 'CANCELLED').

Pada percobaan pertama, nilai 'EXPIRED' ditolak oleh parser PostgreSQL karena dianggap sebagai representasi teks tidak sah untuk ENUM tersebut (galat 22P02).

Perintah ALTER TYPE ... ADD VALUE 'EXPIRED' memperluas definisi tipe data di dalam katalog sistem (pg_enum). Oleh karena itu, eksekusi pembaruan berikutnya berhasil tanpa galat (UPDATE 1).


### Q8

** Perintah : **
-- Diminta: mengedit kolom tags (array) dengan 3 nilai dan melakukan pencarian menggunakan operator array.
-- Dipilih: operator `= ANY()` untuk memeriksa keberadaan elemen di dalam array secara langsung.
-- Alternatif: operator containment `@>`; tidak dipilih karena `= ANY()` lebih eksplisit untuk pencarian tunggal.

-- 1. Isi tags dengan tiga nilai
UPDATE lab5.rental_tx 
SET tags = ARRAY['promo', 'akhir-pekan', 'anggota'] 
WHERE rental_id = 1;

-- 2. Cari baris yang memiliki tag 'promo'
SELECT rental_id, tags 
FROM lab5.rental_tx 
WHERE 'promo' = ANY(tags);

** Keluaran : **
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p05)
$ python -c "
import psycopg
conn = psycopg.connect('postgresql://msbd:msbd2026@localhost:5432/pagila')
cur = conn.cursor()
cur.execute(open('latihan/p05/q08_tags_array.sql', 'r', encoding='utf-8').read())
conn.commit()
cur.execute(\"SELECT rental_id, tags FROM lab5.rental_tx WHERE 'promo' = ANY(tags);\")
print('Hasil Q8:', cur.fetchall())
"
Hasil Q8: [(1, ['promo', 'akhir-pekan', 'anggota'])]

** Alasan : **
['promo', 'akhir-pekan', 'anggota']?
PostgreSQL mendukung tipe data larik/array (text[]). Saat melakukan UPDATE, operator ARRAY[...] mengemas nilai menjadi satu kesatuan elemen struktur data. Ketika diakses menggunakan operator 'promo' = ANY(tags), PostgreSQL memindai seluruh elemen array secara efisien. Driver psycopg 3 secara otomatis mengonversi tipe array PostgreSQL menjadi tipe data native Python (list).


### Q9

** Perintah : **
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

** Keluaran : **
Fakhry Adrian@Fakhry MINGW64 ~/OneDrive/Documents/Tubes_MSBD/K2_MSBD (latihan/p05)
$ python -c "
import psycopg
conn = psycopg.connect('postgresql://msbd:msbd2026@localhost:5432/pagila')
cur = conn.cursor()
cur.execute(open('latihan/p05/q09_metadata_jsonb.sql', 'r', encoding='utf-8').read())
conn.commit()
cur.execute(\"SELECT rental_id, metadata ->> 'channel' AS kanal FROM lab5.rental_tx WHERE rental_id = 1;\")
print('Hasil Q9:', cur.fetchall())
"
Hasil Q9: [(1, 'web')]

** Alasan : **
Tipe data jsonb menyimpan dokumen JSON dalam format biner yang sudah terkompresi dan terurai (parsed). Operator ->> digunakan secara khusus untuk mengekstraksi nilai dari kunci "channel" dan mengonversinya langsung menjadi tipe data teks biasa (text). Jika menggunakan operator -> (tanpa tanda >), outputnya akan tetap berupa objek jsonb bertanda petik ("web").


###Q10: SELECT berparameter

Query: SELECT * FROM film WHERE title = %s
Parameter: ('ACADEMY DINOSAUR',)
Hasil: [(1, 'ACADEMY DINOSAUR', 'A Epic Drama of a Feminist And a Mad Scientist who must Battle a Teacher in The Canadian Rockies', 2006, 1, None, 6, Decimal('0.99'), 86, Decimal('20.99'), 'PG', datetime.datetime(2017, 9, 10, 14, 46, 3, 905795, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC')), ['Deleted Scenes', 'Behind the Scenes'], "'academi':1 'battl':15 'canadian':20 'dinosaur':2 'drama':5 'epic':4 'feminist':8 'mad':11 'must':14 'rocki':21 'scientist':12 'teacher':17")]


###Q11
SQL rawan (hanya dicetak, TIDAK dijalankan):
SELECT * FROM customer WHERE last_name = 'SMITH' OR '1'='1'

Menjalankan versi aman (parameterized) dengan payload yang sama:
Hasil (harus kosong []): []


###Q12: Identifier & allow-list

Berhasil dieksekusi, tetapi parameter dianggap sebagai nilai konstan, bukan nama kolom
Query setelah perbaikan: SELECT * FROM film ORDER BY "release_year"
Hasil: [(1, 'ACADEMY DINOSAUR', 'A Epic Drama of a Feminist And a Mad Scientist who must Battle a Teacher in The Canadian Rockies', 2006, 1, None, 6, Decimal('0.99'), 86, Decimal('20.99'), 'PG', datetime.datetime(2017, 9, 10, 14, 46, 3, 905795, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC')), ['Deleted Scenes', 'Behind the Scenes'], "'academi':1 'battl':15 'canadian':20 'dinosaur':2 'drama':5 'epic':4 'feminist':8 'mad':11 'must':14 'rocki':21 'scientist':12 'teacher':17"), (2, 'ACE GOLDFINGER', 'A Astounding Epistle of a Database Administrator And a Explorer who must Find a Car in Ancient China', 2006, 1, None, 3, Decimal('4.99'), 48, Decimal('12.99'), 'G', datetime.datetime(2017, 9, 10, 14, 46, 3, 905795, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC')), ['Trailers', 'Deleted Scenes'], "'ace':1 'administr':9 'ancient':19 'astound':4 'car':17 'china':20 'databas':8 'epistl':5 'explor':12 'find':15 'goldfing':2 'must':14"), (3, 'ADAPTATION HOLES', 'A Astounding Reflection of a Lumberjack And a Car who must Sink a Lumberjack in A Baloon Factory', 2006, 1, None, 7, Decimal('2.99'), 50, Decimal('18.99'), 'NC-17', datetime.datetime(2017, 9, 10, 14, 46, 3, 905795, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC')), ['Trailers', 'Deleted Scenes'], "'adapt':1 'astound':4 'baloon':19 'car':11 'factori':20 'hole':2 'lumberjack':8,16 'must':13 'reflect':5 'sink':14"), (4, 'AFFAIR PREJUDICE', 'A Fanciful Documentary of a Frisbee And a Lumberjack who must Chase a Monkey in A Shark Tank', 2006, 1, None, 5, Decimal('2.99'), 117, Decimal('26.99'), 'G', datetime.datetime(2017, 9, 10, 14, 46, 3, 905795, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC')), ['Commentaries', 'Behind the Scenes'], "'affair':1 'chase':14 'documentari':5 'fanci':4 'frisbe':8 'lumberjack':11 'monkey':16 'must':13 'prejudic':2 'shark':19 'tank':20"), (5, 'AFRICAN EGG', 'A Fast-Paced Documentary of a Pastry Chef And a Dentist who must Pursue a Forensic Psychologist in The Gulf of Mexico', 2006, 1, None, 6, Decimal('2.99'), 130, Decimal('22.99'), 'G', datetime.datetime(2017, 9, 10, 14, 46, 3, 905795, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC')), ['Deleted Scenes'], "'african':1 'chef':11 'dentist':14 'documentari':7 'egg':2 'fast':5 'fast-pac':4 'forens':19 'gulf':23 'mexico':25 'must':16 'pace':6 'pastri':10 'psychologist':20 'pursu':17")]


###Q13: Rollback dari aplikasi

Jumlah baris SEBELUM: 16044
Exception ditangkap: gagal di tengah alur
Jumlah baris SESUDAH: 16044
Penjelasan: karena exception dilempar SEBELUM blok 'with conn.transaction()' selesai, psycopg otomatis ROLLBACK seluruh transaksi -> jumlah baris tidak berubah.


###Q14: ConnectionPool

Statistik pool: {'requests_num': 5, 'requests_queued': 1, 'connections_num': 2, 'connections_ms': 64, 'requests_wait_ms': 32, 'usage_ms': 15, 'pool_min': 2, 'pool_max': 2, 'pool_size': 2, 'pool_available': 2, 'requests_waiting': 0}


## Refleksi A
Setelah Q3 dan Q4, siapa yang memulai transaksi, siapa yang mengakhirinya, dan bagaimana kelompok membuktikannya dari data?
>> Siapa yang memulai transaksi?
Transaksi dimulai oleh klien atau aplikasi pemanggil eksternal. Setiap kali koneksi membuka eksekusi perintah atau pemanggilan prosedur (CALL), sesi klien otomatis bertindak sebagai pengendali awal transaksi.

Siapa yang mengakhirinya?
Transaksi diakhiri oleh klien pemanggil (melalui perintah commit() atau rollback() di Python, atau COMMIT/ROLLBACK otomatis/manual di level sesi). Prosedur PL/pgSQL sendiri tidak boleh mengakhiri transaksi (tidak boleh ada COMMIT atau ROLLBACK di dalam prosedur), karena jika dipaksa (seperti pada Q4), PostgreSQL akan langsung menolak dan memunculkan galat invalid transaction termination.

Bagaimana kelompok membuktikannya dari data?
Kelompok membuktikannya melalui dua skenario pengujian utama:

Pengujian Q3 (Pembuktian Rollback): Saat prosedur dipanggil dengan parameter negatif (p_amount = -4.99), prosedur langsung memicu RAISE EXCEPTION. Ketika koneksi di-rollback lewat eksekusi luar, jumlah baris pada tabel lab5.rental_tx tetap sama (tidak bertambah), membuktikan bahwa seluruh rangkaian perubahan data dibatalkan secara atomik.

Pengujian Q4 (Pembuktian Batas Transaksi): Saat prosedur yang disisipi perintah COMMIT dipanggil dari dalam blok transaksi Python (with psycopg.connect(...)), terminal langsung mengeluarkan galat invalid transaction termination. Hal ini membuktikan bahwa prosedur tidak memiliki hak untuk mengatur transaksi jika dipanggil dari konteks eksternal.

## Refleksi B
Pilih tags atau metadata. Apakah sebaiknya tetap di sana atau dipindahkan menjadi tabel? Berikan satu pertanyaan bisnis yang dapat mengubah keputusan tersebut.
>> Untuk kebutuhan sistem saat ini, tags sebaiknya tetap disimpan di tabel rental_tx sebagai tipe data text[] (array), bukan dipisah ke tabel relasi baru (rental_tags). Alasannya yaitu tags berfungsi sebagai metadata/label sederhana tanpa atribut tambahan (seperti created_at, deskripsi tag, atau created_by), lalu mencegah operasi JOIN tambahan saat aplikasi membaca transaksi penyewaan, dan PostgreSQL memiliki indeks GIN (Generalized Inverted Index) yang efisien jika pencarian tag di dalam array memerlukan optimasi di masa mendatang.

Pertanyaan bisnis yang dapat mengubah keputusan yaitu, "Apakah tim manajemen memerlukan analitik terpusat mengenai daftar master tag resmi beserta pembatasan hak akses dan laporan statistik penggunaan tag lintas seluruh modul sistem?". Jika jawabannya Ya, maka tags wajib dipindahkan ke tabel master tersendiri (misal: lab5.tag dan lab5.rental_tag) untuk menjaga integritas data (menghindari ketidakkonsistenan akibat typo seperti 'promo' vs 'promosi') dan mempermudah agregasi.

## Refleksi C
Rollback pada Q3 dipicu oleh database: RAISE EXCEPTION di dalam lab5.process_rental ketika p_amount negatif, sehingga Postgres sendiri yang membatalkan transaksi sebelum baris apapun tersimpan. Rollback pada Q13 dipicu oleh aplikasi: prosedurnya sendiri berhasil dijalankan tanpa error SQL, tapi RuntimeError di kode Python membuat context manager with psycopg.connect(...) memanggil rollback() sebelum sempat commit().

Persamaannya: keduanya sama-sama memanfaatkan sifat atomik transaksi Postgres — begitu satu blok transaksi dibatalkan (apapun pemicunya), seluruh perubahan multi-INSERT di dalamnya (baik rental_tx maupun payment_tx) ikut batal bersama, tidak ada data setengah jadi yang tertinggal.

Satu hal yang hanya bisa dilakukan sisi aplikasi: membatalkan transaksi berdasarkan kondisi yang tidak diketahui oleh database — misalnya gagalnya pemanggilan API eksternal, aturan bisnis yang butuh data di luar database, atau keputusan berdasarkan hasil beberapa query terpisah. Database tidak bisa tahu hal-hal ini karena validasinya (RAISE EXCEPTION) hanya bisa melihat data yang ada di dalam query/prosedur itu sendiri, sedangkan aplikasi bisa menggabungkan logika dari mana saja sebelum memutuskan commit atau rollback.