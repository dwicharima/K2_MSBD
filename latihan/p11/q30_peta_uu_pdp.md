# Q30 - Peta Tiket #1134 ke UU PDP

## Tujuan
Memetakan lima keluhan pada Tiket #1134
dengan kewajiban atau hak dalam UU Nomor 27 Tahun 2022
tentang Pelindungan Data Pribadi.

## Pemetaan Keluhan

| Keluhan | Pasal relevan | Kontrol teknis pencegah | Bukti |
|---|---|---|---|
| Keluhan 1: [Satu akun aplikasi (app_admin) memegang seluruh kunci (pemilik semua tabel), sehingga bug di modul laporan menjalankan DROP TABLE dan basis data mematuhinya.] | [Pasal 35 UU No. 27 Tahun 2022 (kewajiban melindungi dan mengamankan data pribadi)] | [Peran berlapis (skema_owner tanpa login, peran fungsional app_read/app_write, dan peran login terpisah seperti app_laporan/app_portal dengan hak minimum).] | [Hasil Q1, Q2, dan Q5 (pemilik bisa mengatur/mengembalikan hak atau memegang hak bawaan DROP, sedangkan peran login seperti app_laporan ditolak saat DROP TABLE / UPDATE).] |
| Keluhan 2: [Penyewa A membaca data penyewa B selama sebelas hari karena satu endpoint laporan lupa menulis WHERE tenant_id.] | [Pasal 35 UU No. 27 Tahun 2022 (kewajiban melindungi dan mengamankan data pribadi dari akses yang tidak sah)] | [Row-Level Security (RLS) dengan CREATE POLICY (USING / WITH CHECK), FORCE ROW LEVEL SECURITY, dan konteks SET LOCAL di dalam transaksi.] | [Hasil Q6–Q11 (isolasi antar-penyewa dengan RLS, FORCE RLS, SET LOCAL, serta pencegahan kebocoran lintas penyewa / SECURITY DEFINER / connection pool).] |
| Keluhan 3: [Kotak pencarian menerima tanda kutip dan merangkai query dengan penyambungan string, sehingga masukan sederhana membuka seluruh baris/tabel termasuk kolom yang tak dimaksudkan tampil.] | [Pasal 39 UU No. 27 Tahun 2022 (kewajiban menjaga kerahasiaan data pribadi)] | [Query berparameter ($1 / %s) untuk memisahkan perintah dan data, serta daftar putih (whitelist) untuk pengenal seperti kolom atau arah urut.] | [Hasil Q12–Q17 (perbandingan sambungan string vs query berparameter, daftar putih ORDER BY, dan second-order injection).] |
| Keluhan 4: [Cadangan berpindah tangan tanpa perlindungan (pg_dump dan arsip WAL berisi NIK dan nomor rekening teks biasa disalin ke flash disk laptop analis yang tak tercatat).] | [Pasal 35 UU No. 27 Tahun 2022 (kewajiban melindungi dan mengamankan data pribadi)] | [Enkripsi saat diam / enkripsi berkas cadangan, penyamaran salinan data (view tersamar / dump tersamar), serta pencatatan pemegang salinan.] | [Hasil Q21–Q24 (pgp_sym_encrypt pada rekening_enc, pemeriksaan aktivitas/log pada Q22, akses tersamar via v_pelanggan_samar pada Q23, serta uji irisan kuasi-pengidentifikasi/agregat pada Q24).] |
| Keluhan 5: [Permintaan hapus datang, baris di tabel utama hilang tapi data masih ada di cadangan, replica, dan ekspor, serta siapa yang pernah membaca tidak tercatat.] | [Pasal 43 (hak menghapus data pribadi) dan Pasal 31 (kewajiban merekam kegiatan pemrosesan) UU No. 27 Tahun 2022] | [Pencatatan permintaan hapus sebagai data, jadwal retensi dan penerapan ulang daftar hapus saat pemulihan, serta jejak audit lewat trigger SECURITY DEFINER.] | [Q25–Q29 (jejak_audit + trigger rekam_audit() SECURITY DEFINER pada Q25–Q27, serta tabel permintaan_hapus dan penghapusan data uji pada Q28–Q29).] |

## Kesimpulan

Kontrol teknis pada praktikum digunakan untuk membantu
melindungi data pribadi, membatasi akses, mencatat aktivitas,
dan menangani permintaan penghapusan data.