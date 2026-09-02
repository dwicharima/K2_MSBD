CREATE TABLE anggota_tim (
    id_tim bigint NOT NULL REFERENCES tim(id_tim),
    nim varchar(16) NOT NULL REFERENCES mahasiswa(nim),
    PRIMARY KEY (id_tim, nim)
);