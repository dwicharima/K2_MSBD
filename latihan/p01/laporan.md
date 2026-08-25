Langkah 1 : 












Langkah 2 
Pertanyaan Wajib :

1. Apa yang terjadi jika bagian volumes: pada layanan PostgreSQL dihapus, kemudian container dihentikan menggunakan docker compose down -v? 
Jawabannya : Semua data di dalam database PostgreSQL bakal terhapus secara permanen. Perintah down -v otomatis menghapus named volume (pgdata) tempat penyimpanan berkas fisik database di luar containernya. Tanpa volumes, data juga tidak akan tersimpan secara aman jika container dimatikan. 

2. Mengapa pemetaan port ditulis "5432:5432" dan bukan cukup satu angka? Apa yang harus diubah apabila komputer Anda sudah memiliki PostgreSQL lain yang menggunakan port 5432? 
Jawaban : Karena angka pertama 5432 adalah port di host, sedangkan angka kedua 5432 adalah port yang berjalan di dalam container Docker. Kedua angka ini diperlukan untuk menjembatani koneksi dari luar ke dalam container. Kita harus mengubah angka bagian depan menjadi port lain yang masih kosong, misalnya "5433:5432", sehingga akses dari luar laptop akan melalui port 5433 dan diarahkan ke port 5432 di dalam container. 

3. Apa fungsi blok healthcheck? Mengapa healthcheck penting ketika terdapat layanan lain yang bergantung pada basis data? 
Jawaban :  
Fungsi blok healthcheck untuk memantau dan menguji secara berkala apakah layanan di dalam container (seperti PostgreSQL) benar-benar sudah hidup dan siap digunakan sepenuhnya. 
Kepentingannya untuk layanan lain sangat penting supaya layanan lain (seperti backend) tidak langsung mencoba melakukan koneksi saat database masih dalam proses memulai atau belum siap, sehingga dapat mencegah terjadinya koneksi eror. 

4. Menyimpan password langsung di dalam docker-compose.yml merupakan praktik yang kurang baik. Sebutkan satu cara yang lebih aman dan jelaskan mengapa hal tersebut penting ketika berkas masuk ke repositori Git. 
Jawaban : 
Cara aman menyimpan password selain di docker-compose.yml yaitu dengan menggunakan file terpisah berbasis environment variables (seperti file .env) yang dipasangkan dengan fungsi environment. File .env ini nantinya ditambahkan ke dalam .gitignore supaya tidak ikut ter-upload. 
Mengapa hal tersebut penting ketika masuk ke repositori Git? Agar data yang bersifat rahasi tidak bocor ke publik atau ketahuan orang lain di GitHub. Kalau file docker-compose.yml yang ada password-nya di-commit ke Git (terutama repositorinya public), siapa saja bisa melihat password database kita dan membahayakan keamanan sistem. 
 