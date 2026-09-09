# Laporan Latihan Kelompok 2 Pertemuan 3

## Anggota Kelompok

- Rasyd Arija Azron Ritonga | 251402020 |
- Fakhry Adrian Daulay | 251402053 |
- Dwi Charima Husni | 251402088 |- Project Manager
- Agnes Natalia Br Siregar | 251402108 |
- Abdullah Zufar Aulia Nasution | 251402111 |


## Refleksi A - Subquery

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

## Refleksi B - CTE dan Recursive CTE

1. Pada Q7, mengapa recursive term hanya melihat baris yang baru dihasilkan pada iterasi sebelumnya, dan apa akibatnya jika ia melihat seluruh hasil?
> Recursive CTE bekerja dengan "working table": tiap putaran hanya memproses baris baru dari putaran sebelumnya, bukan seluruh hasil yang terkumpul. Kalau ia memproses seluruh hasil, baris lama ikut diulang terus tiap putaran, sehingga jumlah baris membengkak (bisa eksponensial) dan pada data yang bersiklus query tidak akan pernah berhenti.

2. Kapan mengganti UNION ALL dengan UNION dapat menghentikan siklus, dan mengapa itu tetap bukan solusi yang baik?
> UNION hanya menghentikan siklus kalau baris yang berulang persis sama di semua kolom. Pada Q7, kolom level dan jalur selalu berubah tiap putaran, jadi baris tidak pernah benar-benar identik dan siklus tetap jalan terus — UNION tidak bisa diandalkan. Selain itu UNION lebih mahal karena harus membandingkan seluruh kolom setiap baris untuk deteksi duplikat, padahal solusi seperti array jalur (NOT (id = ANY(jalur_id))) langsung menyasar akar masalah (id yang berulang) dengan biaya lebih murah dan maksud yang lebih jelas.

##  Reflektif D
1. Pada Q16, tanpa GROUPING(), bagaimana pembaca membedakan subtotal dari baris data yang kolomnya memang kosong?
> Pada Q16, tanpa GROUPING(), pembaca sulit membedakan apakah nilai NULL pada kolom hasil grouping merupakan subtotal atau memang nilai kolom data yang kosong (NULL). GROUPING() digunakan untuk menandai apakah NULL tersebut berasal dari baris subtotal/rollup atau dari data asli.

2. Pada Q17, mengapa versi FILTER dan CASE WHEN dapat memberi rata-rata berbeda walaupun jumlah baris sama?
> Pada Q17, FILTER dan CASE WHEN dapat menghasilkan rata-rata berbeda karena cara menghitungnya berbeda. FILTER menghitung agregat hanya pada baris yang memenuhi kondisi, sedangkan CASE WHEN dapat menghasilkan NULL pada baris yang tidak memenuhi kondisi dan kemudian AVG() hanya menghitung nilai yang bukan NULL. Jika ekspresi atau kondisi yang digunakan tidak benar-benar ekuivalen, jumlah baris yang masuk ke perhitungan rata-rata bisa berbeda, sehingga hasil AVG() juga berbeda.