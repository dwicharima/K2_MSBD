Laporan Latihan - Pertemuan 1 - Kelompok 2 - Manajemen Sistem Basis Data

Anggota Kelompok :
- Rasyd Arija Azron Ritonga (251402020)
- Fakhry Adrian Daulay (251402053)
- Dwi Charima Husni (251402088) - Project Manager
- Agnes Natalia Br Siregar (251402108)
- Abdullah Zufar Aulia Nasution (251402111)

Langkah 1
Pertanyaan Pemahaman :
Jawab menggunakan kalimat Anda sendiri: 

1. Apa yang dimaksud dengan Docker Image? 
Jawaban :
Docker Image adalah blueprint yang berisi kebutuhan-kebutuhan kita untuk menjalankan sebuah aplikasi di dalam kontainer Docker. 

2. Apa yang dimaksud dengan Container? 
Jawaban :
Container adalah environment dengan versi dependency yang sama yang digunakan untuk menjalankan aplikasi beserta semua yang diperlukan pada aplikasi tersebut. 

3. Apa fungsi Volume? 
Jawaban :
Volume adalah penyimpanan aman yang digunakan untuk menyimpan data agar tetap ada meskipun container dihapus atau dibuat ulang. 

Langkah 2 
Pertanyaan Wajib :

1. Apa yang terjadi jika bagian volumes: pada layanan PostgreSQL dihapus, kemudian container dihentikan menggunakan docker compose down -v? 
Jawaban : 
Semua data di dalam database PostgreSQL bakal terhapus secara permanen. Perintah down -v otomatis menghapus named volume (pgdata) tempat penyimpanan berkas fisik database di luar containernya. Tanpa volumes, data juga tidak akan tersimpan secara aman jika container dimatikan. 

2. Mengapa pemetaan port ditulis "5432:5432" dan bukan cukup satu angka? Apa yang harus diubah apabila komputer Anda sudah memiliki PostgreSQL lain yang menggunakan port 5432? 
Jawaban : 
Karena angka pertama 5432 adalah port di host, sedangkan angka kedua 5432 adalah port yang berjalan di dalam container Docker. Kedua angka ini diperlukan untuk menjembatani koneksi dari luar ke dalam container. Kita harus mengubah angka bagian depan menjadi port lain yang masih kosong, misalnya "5433:5432", sehingga akses dari luar laptop akan melalui port 5433 dan diarahkan ke port 5432 di dalam container. 

3. Apa fungsi blok healthcheck? Mengapa healthcheck penting ketika terdapat layanan lain yang bergantung pada basis data? 
Jawaban :  
Fungsi blok healthcheck untuk memantau dan menguji secara berkala apakah layanan di dalam container (seperti PostgreSQL) benar-benar sudah hidup dan siap digunakan sepenuhnya. 
Kepentingannya untuk layanan lain sangat penting supaya layanan lain (seperti backend) tidak langsung mencoba melakukan koneksi saat database masih dalam proses memulai atau belum siap, sehingga dapat mencegah terjadinya koneksi eror. 

4. Menyimpan password langsung di dalam docker-compose.yml merupakan praktik yang kurang baik. Sebutkan satu cara yang lebih aman dan jelaskan mengapa hal tersebut penting ketika berkas masuk ke repositori Git. 
Jawaban : 
Cara aman menyimpan password selain di docker-compose.yml yaitu dengan menggunakan file terpisah berbasis environment variables (seperti file .env) yang dipasangkan dengan fungsi environment. File .env ini nantinya ditambahkan ke dalam .gitignore supaya tidak ikut ter-upload. 
Mengapa hal tersebut penting ketika masuk ke repositori Git? Agar data yang bersifat rahasi tidak bocor ke publik atau ketahuan orang lain di GitHub. Kalau file docker-compose.yml yang ada password-nya di-commit ke Git (terutama repositorinya public), siapa saja bisa melihat password database kita dan membahayakan keamanan sistem. 

Langkah 3 

1. Satu aktivitas yang menurut Anda lebih cepat dilakukan menggunakan psql.
Jawaban : 
Menjalankan beberapa perintah SQL secara langsung, terutama saat ingin melakukan pengecekan sederhana terhadap database. Dengan psql, perintah bisa langsung ditulis di terminal sehingga prosesnya lebih praktis dan tidak perlu berpindah-pindah tampilan.

2. Satu aktivitas yang menurut Anda lebih cepat dilakukan menggunakan DBeaver.
Jawaban : 
Melihat dan memeriksa isi tabel karena data langsung ditampilkan dalam bentuk tabel yang rapi. DBeaver juga memudahkan untuk melihat kolom dan isi data tanpa harus menulis query untuk setiap pengecekan.

3. Perbandingan penggunaan psql dan DBeaver
Jawaban : 
Psql lebih praktis digunakan untuk menjalankan perintah SQL secara langsung melalui terminal. Cocok untuk aktivitas yang sederhana dan cepat, seperti menjalankan query, mengecek database, atau melakukan administrasi dasar tanpa membuka aplikasi dengan tampilan grafis. DBeaver lebih nyaman digunakan untuk mengelola dan melihat database melalui antarmuka grafis. DBeaver memudahkan ketika ingin melihat tabel, struktur kolom, isi data, relasi antar tabel, atau ER Diagram karena semuanya dapat ditampilkan secara visual.
Jadi, psql lebih unggul untuk eksekusi perintah yang cepat dan langsung, sedangkan DBeaver lebih unggul untuk pengelolaan dan visualisasi database.

Langkah 4
== Restore Basis Data Pagila dan Verifikasi ==

Setelah database pagila berhasil di-restore dari berkas dump, saya menjalankan empat query verifikasi (V1-V4) untuk memastikan datanya masuk dengan benar dan untuk melihat performa query di dalamnya.

V1 - Jumlah tabel pada skema public Hasil: 21 tabel. Jumlah ini cocok dengan hasil \dt sebelumnya, jadi seluruh tabel dari dump pagila sudah masuk dengan lengkap ke skema public.

V2 - Sepuluh tabel terbesar beserta ukurannya Hasil: 
     relname      | ukuran  
------------------+---------
 rental           | 2472 kB
 payment_p2017_04 | 1856 kB
 payment_p2017_03 | 1536 kB
 film             | 952 kB
 payment_p2017_02 | 728 kB
 film_actor       | 576 kB
 payment_p2017_01 | 448 kB
 inventory        | 440 kB
 customer         | 224 kB
 address          | 168 kB
(10 rows)
    Tabel rental paling besar karena menyimpan seluruh riwayat transaksi penyewaan film sedangkan tabel payment terpisah per bulan (partisi) sehingga ukurannya lebih kecil per tabelnya.

V3 - Lima film dengan jumlah penyewaan terbanyak Hasil: 
        title        | total_sewa 
---------------------+------------
 BUCKET BROTHERHOOD  |         34
 ROCKETEER MOTHER    |         33
 RIDGEMONT SUBMARINE |         32
 SCALAWAG DUCK       |         32
 FORWARD TEMPLE      |         32

    Film "BUCKET BROTHERHOOD" adalah film yang paling sering disewa dengan 34 kali penyewaan.

V4 - Melihat rencana eksekusi query (EXPLAIN ANALYZE) Hasil: 

HashAggregate  (cost=761.19..771.19 rows=1000 width=23) (actual time=17.885..18.086 rows=958 loops=1)
   Group Key: f.title
   Batches: 1  Memory Usage: 193kB
   ->  Hash Join  (cost=238.57..672.95 rows=17648 width=15) (actual time=2.208..13.536 rows=16044 loops=1)
         Hash Cond: (i.film_id = f.film_id)
         ->  Hash Join  (cost=128.07..515.92 rows=17648 width=2) (actual time=1.539..8.856 rows=16044 loops=1)
               Hash Cond: (r.inventory_id = i.inventory_id)
               ->  Seq Scan on rental r  (cost=0.00..341.48 rows=17648 width=4) (actual time=0.010..2.399 rows=16044 loops=1)
               ->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=1.511..1.513 rows=4581 loops=1)
                     Buckets: 8192  Batches: 1  Memory Usage: 234kB
                     ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.008..0.708 rows=4581 loops=1)
         ->  Hash  (cost=98.00..98.00 rows=1000 width=19) (actual time=0.661..0.662 rows=1000 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 60kB
               ->  Seq Scan on film f  (cost=0.00..98.00 rows=1000 width=19) (actual time=0.015..0.382 rows=1000 loops=1)
 Planning Time: 0.628 ms
 Execution Time: 18.193 ms

Pertanyaan:
"Yang paling membingungkan dari keluaran ini adalah perbedaan antara angka cost (perkiraan biaya query menurut planner, sebelum query dijalankan) dengan actual time (waktu nyata dalam milidetik saat query benar-benar dieksekusi), serta banyaknya proses bertingkat seperti Hash Join dan Seq Scan yang saling bersarang sehingga sulit menentukan bagian mana yang paling menyita waktu hanya dengan sekali baca."