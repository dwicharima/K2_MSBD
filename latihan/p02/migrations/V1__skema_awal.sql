CREATE TABLE mahasiswa (
    nim varchar(16) PRIMARY KEY,
    nama_mahasiswa varchar(120) NOT NULL,
    program_studi varchar(100) NOT NULL,
    angkatan integer NOT NULL,
    nomor_telepon varchar(20) NOT NULL
);

CREATE TABLE tim (
    id_tim bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_tim varchar(100) NOT NULL,
    asal_program_studi varchar(100) NOT NULL,
    nama_ketua varchar(120) NOT NULL,
    status_tim varchar(20) NOT NULL DEFAULT 'aktif'
        CHECK (status_tim IN ('aktif', 'didiskualifikasi', 'selesai'))
);

CREATE TABLE kompetisi (
    id_kompetisi bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_kompetisi varchar(150) NOT NULL,
    jenis_kompetisi varchar(50) NOT NULL,
    tanggal_mulai date NOT NULL,
    tanggal_selesai date NOT NULL,
    lokasi varchar(150) NOT NULL,
    status varchar(20) NOT NULL DEFAULT 'dibuka'
        CHECK (status IN ('dibuka', 'berlangsung', 'selesai'))
);

CREATE TABLE pendaftaran_tim (
    id_pendaftaran bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tim bigint NOT NULL REFERENCES tim(id_tim),
    id_kompetisi bigint NOT NULL REFERENCES kompetisi(id_kompetisi),
    tanggal_pendaftaran date NOT NULL DEFAULT current_date,
    status_pendaftaran varchar(20) NOT NULL DEFAULT 'terdaftar'
        CHECK (status_pendaftaran IN ('terdaftar', 'diverifikasi', 'ditolak'))
);