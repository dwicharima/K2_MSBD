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


** Keluaran : **








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

