### Cara Menjalankan q00_setup.sql
Sebelum mengeksekusi rangkaian kueri, lingkungan dan tabel dasar pada skema lab4 wajib disiapkan. Kemudian menjalankan perintah berikut melalui terminal Git Bash:

docker exec -i msbd-pg psql -U msbd -d latihan < latihan/p04/q00_setup.sql
Perintah ini akan membuat skema lab4, mempersiapkan tabel dasar (film, jejak_akses), serta mengisi data awal.

### Urutan Pengerjaan Q1–Q21

Q1 (q01_view_film_murah.sql): Pembuatan view standar (lab4.film_murah) untuk menyaring film berdasarkan kriteria harga sewa (rental_rate <= 0.99) tanpa pengaman tambahan.

Q2 (q02_baris_menghilang.sql): Demonstrasi silent filtering saat melakukan penyisipan data di luar rentang saringan view.

Q3 (q03_check_option.sql): Implementasi WITH CASCADED CHECK OPTION guna memaksa penolakan terhadap data yang melanggar aturan saringan view.

Q4 (q04_view_pendapatan_kategori.sql): Analisis keterbatasan view dengan fungsi agregat dan GROUP BY yang bersifat not auto-updatable.