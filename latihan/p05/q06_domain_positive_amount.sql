-- Diminta: memasukkan nilai nol dan negatif ke lab5.payment_tx untuk menguji domain positive_amount.
-- Dipilih: dua statement INSERT terpisah untuk merekam galat masing-masing batas nilai secara presisi.
-- Alternatif: satu INSERT dengan multiple values; tidak dipilih karena eksekusi terhenti pada galat pertama.

-- 1. Uji nilai nol (0.00)
INSERT INTO lab5.payment_tx (rental_id, amount) 
VALUES (1, 0.00);

-- Galat yang dihasilkan:
-- ERROR:  value for domain lab5.positive_amount violates check constraint "positive_amount_check"
-- SQLSTATE: 23514

-- 2. Uji nilai negatif (-15.50)
INSERT INTO lab5.payment_tx (rental_id, amount) 
VALUES (1, -15.50);

-- Galat yang dihasilkan:
-- ERROR:  value for domain lab5.positive_amount violates check constraint "positive_amount_check"
-- SQLSTATE: 23514