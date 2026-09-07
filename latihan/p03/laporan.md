# Laporan Latihan - Pertemuan 3 - Kelompok 2 - Manajemen Sistem Basis Data

**Anggota Kelompok :**

- Rasyd Arija Azron Ritonga (251402020)
- Fakhry Adrian Daulay (251402053)
- Dwi Charima Husni (251402088) - Project Manager
- Agnes Natalia Br Siregar (251402108)
- Abdullah Zufar Aulia Nasution (251402111)

### Langkah 3

**Pertanyaan Reflektif A**

1. Pada Q4, apa tepatnya yang membuat NOT IN berbahaya, dan bagaimana memeriksa apakah sebuah kolom rawan terhadap masalah itu?
> Penyebab bahaya NOT IN adalah mengevaluasi kondisi keanggotaan menggunakan logika tiga nilai (Three-Valued Logic) SQL (TRUE, FALSE, UNKNOWN). Jika subquery mengembalikan bahkan satu saja nilai NULL, seluruh ekspresi WHERE col NOT IN akan mengevaluasi baris menjadi UNKNOWN (karena tidak bisa memastikan apakah sebuah nilai yang tidak diketahui cocok atau tidak). Akibatnya, query langsung mengembalikan 0 baris (kosong) tanpa error sama sekali.

Cara memeriksa apakah kolom rawan: 
Cek apakah kolom yang dijadikan target di subquery memiliki potensi atau batasan NULL (NOT NULL). Kamu bisa jalankan query pengecekan sederhana seperti:

SQL
SELECT COUNT(*) FROM nama_tabel WHERE nama_kolom IS NULL;
Jika hasilnya > 0, kolom tersebut sangat rawan membuat NOT IN gagal total. Sebagai pencegahan yang aman, lebih baik beralih menggunakan NOT EXISTS atau menambahkan filter WHERE nama_kolom IS NOT NULL di dalam subquery.


2. Pada Q5, berapa kali subquery dievaluasi secara konseptual, dan mengapa “sekali per baris luar” belum tentu sama dengan yang benar-benar dikerjakan mesin?
> Secara konseptual, subquery berkorelasi dievaluasi sekali buat tiap baris di tabel luar. Jadi kalau tabel luarnya ada 1.000 baris,  subquery-nya dijalankan satu-satu sebanyak 1.000 kali.

Tapi, Pada mesin database, hal itu belum tentu dikerjakan seperti itu. Query Optimizer modern (PostgreSQL) mesin database sering melakukan subquery unnesting (mengubah subquerynya jadi operasi JOIN) atau caching hasil. Jadi, eksekusi aslinya bisa jauh lebih optimize dan nggak bener-bener ngeloop dari nol terus-terusan setiap baris.