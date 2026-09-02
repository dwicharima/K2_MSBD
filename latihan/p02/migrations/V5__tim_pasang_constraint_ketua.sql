ALTER TABLE tim
ALTER COLUMN nim_ketua SET NOT NULL;

ALTER TABLE tim
ADD CONSTRAINT fk_tim_ketua_mahasiswa
FOREIGN KEY (nim_ketua) REFERENCES mahasiswa(nim);