DROP TABLE IF EXISTS pegawai CASCADE;
CREATE TABLE pegawai (
    pegawai_id int PRIMARY KEY,
    nama text NOT NULL,
    atasan_id int REFERENCES pegawai(pegawai_id)
);

INSERT INTO pegawai VALUES
    (1,'Rina',NULL), (2,'Bima',1), (3,'Sari',1),
    (4,'Toni',2), (5,'Umi',2), (6,'Vino',4), (7,'Wati',3);

DROP TABLE IF EXISTS notifikasi CASCADE;
CREATE TABLE notifikasi (
    notifikasi_id serial PRIMARY KEY,
    diterima_pada timestamptz NOT NULL DEFAULT now(),
    payload jsonb NOT NULL
);

INSERT INTO notifikasi (payload) VALUES
('{
  "trx":"T-001", "status":"lunas", "jumlah":45000,
  "pelanggan":{"id":11,"kota":"Medan"},
  "kontak":[
    {"jenis":"wa","nomor":"0811"},
    {"jenis":"email","nomor":"a@x.id"}
  ]
}'),
('{
  "trx":"T-002", "status":"gagal", "jumlah":98000,
  "pelanggan":{"id":12,"kota":"Binjai"},
  "kontak":[{"jenis":"email","nomor":"b@x.id"}]
}'),
('{
  "trx":"T-003", "status":"lunas", "jumlah":12500,
  "pelanggan":{"id":11,"kota":"Medan"},
  "kontak":[]
}');