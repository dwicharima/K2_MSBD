#### B. Tuliskan Lingkup

## Lingkup

| Termasuk | Tidak termasuk |
|---|---|
| Pendataan mahasiswa dan anggota tim | Data akademik mahasiswa secara keseluruhan |
| Pendataan kompetisi dan kategori kompetisi | Pengelolaan perkuliahan mahasiswa |
| Pendaftaran tim ke dalam kompetisi | Pembayaran biaya kuliah mahasiswa |
| Penjadwalan dan pencatatan pertandingan | Pengadaan perlengkapan kompetisi |
| Pendataan juri dan penilaian pertandingan | Penggajian atau honor juri |
| Pencatatan hasil pertandingan | Pengelolaan transportasi peserta |

#### C. Tuliskan Minimal 8 Kebutuhan Data

```
### KD-01 Data Mahasiswa

- Deskripsi : menyimpan data mahasiswa yang mengikuti kompetisi
- Data      : NIM, nama_mahasiswa, program_studi, angkatan, nomor_telepon
- Aturan    : setiap mahasiswa memiliki NIM yang unik; 
              hanya mahasiswa yang terdaftar yang dapat mengikuti kompetisi
- Volume    : ±5.000 mahasiswa
- Sumber    : data akademik dan formulir pendaftaran
- Prioritas : wajib

### KD-02 Data Tim

- Deskripsi : menyimpan data tim yang dibentuk untuk mengikuti kompetisi
- Data      : id_tim, nama_tim, asal_program_studi, nama_ketua, status_tim
- Aturan    : setiap tim memiliki nama yang unik dalam satu kompetisi; 
              tim harus memiliki anggota sebelum didaftarkan
- Volume    : ±500 tim/tahun
- Sumber    : formulir pendaftaran tim
- Prioritas : wajib

### KD-03 Keanggotaan Tim

- Deskripsi : mencatat mahasiswa yang menjadi anggota dalam suatu tim
- Data      : id_tim, NIM, peran, tanggal_bergabung
- Aturan    : satu tim memiliki beberapa anggota; 
              satu mahasiswa dapat bergabung dalam beberapa tim sesuai ketentuan kompetisi; 
              mahasiswa tidak boleh terdaftar dua kali pada tim yang sama
- Volume    : ±2.500 data keanggotaan/tahun
- Sumber    : formulir pendaftaran tim
- Prioritas : wajib

### KD-04 Data Kompetisi

- Deskripsi : menyimpan informasi kompetisi yang diselenggarakan
- Data      : id_kompetisi, nama_kompetisi, jenis_kompetisi, tanggal_mulai, tanggal_selesai, lokasi, status
- Aturan    : setiap kompetisi memiliki periode pelaksanaan dan periode pendaftaran; 
              kompetisi yang sudah selesai tidak dapat menerima pendaftaran baru
- Volume    : ±20 kompetisi/tahun
- Sumber    : data panitia
- Prioritas : wajib

### KD-05 Pendaftaran Tim

- Deskripsi : mencatat pendaftaran tim pada kompetisi yang dipilih
- Data      : id_tim, id_kompetisi, tanggal_pendaftaran, status_pendaftaran
- Aturan    : satu tim dapat mengikuti beberapa kompetisi dan satu kompetisi dapat diikuti oleh banyak tim; 
              pendaftaran hanya dapat dilakukan selama periode pendaftaran; 
              tim harus memenuhi persyaratan kompetisi
- Volume    : ±1.000 pendaftaran/tahun
- Sumber    : formulir pendaftaran kompetisi
- Prioritas : wajib

### KD-06 Data Pertandingan

- Deskripsi : mencatat jadwal dan hasil pertandingan antar-tim dalam kompetisi
- Data      : id_pertandingan, id_kompetisi, waktu_pertandingan, lokasi, tim_1, tim_2, skor_tim_1, skor_tim_2, status_pertandingan
- Aturan    : hanya tim yang sudah terdaftar dalam kompetisi yang dapat mengikuti pertandingan; 
              satu tim tidak dapat dijadwalkan bertanding pada waktu yang sama di dua pertandingan
- Volume    : ±2.000 pertandingan/tahun
- Sumber    : jadwal dan hasil pertandingan dari panitia
- Prioritas : wajib

### KD-07 Data Juri dan Penugasan Juri

- Deskripsi : menyimpan data juri serta kompetisi yang menjadi tanggung jawabnya
- Data      : id_juri, nama_juri, bidang_keahlian, nomor_telepon, id_kompetisi, tanggal_penugasan
- Aturan    : satu juri dapat ditugaskan pada beberapa kompetisi dan satu kompetisi dapat memiliki beberapa juri; 
              juri yang menjadi peserta dalam suatu kompetisi tidak dapat menjadi juri pada kompetisi tersebut
- Volume    : ±100 juri dan ±200 penugasan/tahun
- Sumber    : data panitia
- Prioritas : wajib

### KD-08 Data Penilaian

- Deskripsi : mencatat penilaian yang diberikan juri terhadap pertandingan atau peserta
- Data      : id_penilaian, id_pertandingan, id_juri, nilai, catatan, waktu_penilaian
- Aturan    : hanya juri yang ditugaskan pada kompetisi tersebut yang dapat memberikan penilaian; 
              nilai harus berada dalam rentang yang telah ditentukan panitia
- Volume    : ±5.000 penilaian/tahun
- Sumber    : formulir penilaian juri
- Prioritas : wajib
```
