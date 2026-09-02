# Laporan Latihan - Pertemuan 1 - Kelompok 2 - Manajemen Sistem Basis Data

**Anggota Kelompok :**
- Rasyd Arija Azron Ritonga (251402020)
- Fakhry Adrian Daulay (251402053)
- Dwi Charima Husni (251402088) - Project Manager
- Agnes Natalia Br Siregar (251402108)
- Abdullah Zufar Aulia Nasution (251402111)

---

### Nama domain dan alasan kelompok memilih domain tersebut.

Nama Domain : Manajemen Kompetisi Antar-Mahasiswa. 
Alasan kami memilih domain ini karena awalnya kami mencari beberapa referensi dari AI untuk mendapatkan beberapa kandidat domain yang bisa digunakan. Setelah melihat dan mempertimbangkan beberapa pilihan, kami akhirnya memilih Manajemen Kompetisi Antar-Mahasiswa.

Kami memilih domain ini karena menurut kami alur kegiatannya cukup jelas dan mudah dipahami. Mulai dari mahasiswa yang membentuk tim, mendaftarkan tim ke kompetisi, mengikuti pertandingan, sampai proses penilaian oleh juri. Data-data yang ada juga saling berhubungan, sehingga menurut kami domain ini cukup menarik dan cocok untuk dibuat ke dalam ERD. Selain itu, terdapat hubungan M dan aturan bisnis yang bisa dikembangkan, sehingga dapat memenuhi kebutuhan tugas yang dib

---

### Ringkasan Lingkup Sistem

Sistem ini digunakan untuk mengelola kompetisi antar-mahasiswa, mulai dari pendataan mahasiswa dan tim, pendaftaran tim ke kompetisi, penjadwalan pertandingan, pendataan juri, hingga pencatatan penilaian dan hasil pertandingan. Sistem tidak mencakup pengelolaan data akademik mahasiswa secara keseluruhan, pembayaran, pengadaan perlengkapan, maupun penggajian juri.

---

### Ringkasan Kebutuhan Data

Kebutuhan data yang kami buat meliputi data mahasiswa, tim, keanggotaan tim, kompetisi, pendaftaran tim, pertandingan, juri dan penugasan juri, serta penilaian. Data-data tersebut digunakan untuk mencatat siapa saja yang mengikuti kompetisi, tim yang terdaftar, hubungan anggota dengan tim, jadwal dan hasil pertandingan, juri yang bertugas, serta nilai yang diberikan. Kebutuhan data ini saling berhubungan sehingga dapat menggambarkan proses kompetisi dari awal pendaftaran sampai penilaian dan hasil pertandingan.

---

### Langkah 1

**Pertanyaan 1**
Mengapa lingkungan pengujian memerlukan basis data sendiri, dan bukan sekadar schema terpisah di dalam basis data yang sama? Jawab dalam sekitar dua kalimat.

> Lingkungan pengujian memerlukan basis data sendiri agar data dan proses pengujian tidak memengaruhi data produksi maupun lingkungan lainnya. Schema terpisah dalam basis data yang sama belum cukup karena masih berbagi sumber daya, konfigurasi, dan risiko kesalahan pada tingkat basis data.

---

### Langkah 2

**Pertanyaan 2**
Pilih satu kebutuhan yang memiliki aturan paling rumit. Menurut kelompok kalian, apakah aturan tersebut lebih tepat ditegakkan menggunakan constraint, trigger, atau kode aplikasi? Berikan satu alasan.

> Menurut kelompok kami kebutuhan yang memiliki aturan paling rumit adalah proses pendaftaran tim dalam kompetisi. Menurut kelompok kami, aturan tersebut lebih tepat ditangani menggunakan kode aplikasi, karena prosesnya dapat melibatkan beberapa pengecekan sekaligus, seperti status kompetisi, jumlah anggota tim, dan apakah tim sudah terdaftar. Kode aplikasi lebih mudah digunakan untuk menangani logika yang kompleks dan memberikan pesan yang jelas kepada pengguna.

---

### Langkah 4

**Pertanyaan 5**
Seorang anggota kelompok mengubah isi V1__skema_awal.sql setelah migration tersebut sudah diterapkan, kemudian melakukan push ke repositori. Apa yang terjadi ketika anggota lain menjalankan migration? Jelaskan penyebab error dan cara memperbaikinya tanpa menghapus riwayat migration.

> Kalau ada anggota kelompok yang ngubah isi file migrasi yang sudah pernah sukses dijalankan (V1__skema_awal.sql), Flyway bakal langsung menolak migrasi dan memunculkan error saat perintah migrate dijalankan di komputer anggota lain.

Penyebab Error
Flyway menggunakan kode verifikasi unik untuk setiap file migrasi SQL yang dijalankan. Kode ini disimpan otomatis ke dalam tabel flyway_schema_history di database saat migrasi pertama kali sukses.

Ketika file V1__skema_awal.sql diubah isinya di repositori, kode verifikasi unik file lokal jadi berbeda dengan kode verifikasi unik  lama yang tercatat di database. Flyway mendeteksi ketidakcocokan ini sebagai potensi kerusakan integritas data atau perubahan skema yang tidak sah pada migrasi yang sudah berlalu, sehingga proses langsung dihentikan.

Cara Memperbaikinya (Tanpa Menghapus Riwayat)
Ada dua cara yang bisa dipakai:

1. Menggunakan Perintah repair
Jika perubahan pada file SQL tersebut sifatnya sepele (misalnya cuma merapikan spasi, komentar, atau format huruf tanpa mengubah struktur tabel yang fatal), cukup menyamakan kode verifikasi unik di database dengan file yang baru pakai perintah Flyway repair.

Jalankan perintah di terminal:
docker compose run --rm flyway -url=jdbc:postgresql://postgres:5432/proyek_dev -user=msbd -password=msbd2026 repair

Perintah ini akan menyuruh Flyway memperbarui catatan kode verifikasi unik di tabel riwayat agar sesuai dengan isi file V1__skema_awal.sql yang baru. Setelah itu, jalankan ulang migrate.

2. Membuat File Migrasi Baru (V2)
Jika perubahan kodenya berupa penambahan kolom, tabel baru, atau perubahan struktur skema yang signifikan, jangan pernah mengubah file V1 yang lama.

Cara yang benar sesuai aturan database:
- Kembalikan file V1__skema_awal.sql ke isi aslinya seperti semula (revert lewat Git).
- Buat file migrasi baru dengan versi berikutnya, contohnya V2__penyesuaian_skema_awal.sql, lalu isi dengan perintah perubahan skema yang baru (misalnya ALTER TABLE ...).
- Push file baru tersebut ke Git agar anggota lain bisa menjalankan migrasi V2 secara aman tanpa merusak riwayat V1.