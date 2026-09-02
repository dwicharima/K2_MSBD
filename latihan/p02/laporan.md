# Laporan Latihan - Pertemuan 1 - Kelompok 2 - Manajemen Sistem Basis Data**

**Anggota Kelompok :**
- Rasyd Arija Azron Ritonga (251402020)
- Fakhry Adrian Daulay (251402053)
- Dwi Charima Husni (251402088) - Project Manager
- Agnes Natalia Br Siregar (251402108)
- Abdullah Zufar Aulia Nasution (251402111)


---

### Langkah 1

**Pertanyaan 1**
Mengapa lingkungan pengujian memerlukan basis data sendiri, dan bukan sekadar schema terpisah di dalam basis data yang sama? Jawab dalam sekitar dua kalimat.

> Lingkungan pengujian memerlukan basis data sendiri agar data dan proses pengujian tidak memengaruhi data produksi maupun lingkungan lainnya. Schema terpisah dalam basis data yang sama belum cukup karena masih berbagi sumber daya, konfigurasi, dan risiko kesalahan pada tingkat basis data.

---

## Langkah 2

**Pertanyaan 2**
Pilih satu kebutuhan yang memiliki aturan paling rumit. Menurut kelompok kalian, apakah aturan tersebut lebih tepat ditegakkan menggunakan constraint, trigger, atau kode aplikasi? Berikan satu alasan.

> Menurut kelompok kami kebutuhan yang memiliki aturan paling rumit adalah proses pendaftaran tim dalam kompetisi. Menurut kelompok kami, aturan tersebut lebih tepat ditangani menggunakan kode aplikasi, karena prosesnya dapat melibatkan beberapa pengecekan sekaligus, seperti status kompetisi, jumlah anggota tim, dan apakah tim sudah terdaftar. Kode aplikasi lebih mudah digunakan untuk menangani logika yang kompleks dan memberikan pesan yang jelas kepada pengguna.

---