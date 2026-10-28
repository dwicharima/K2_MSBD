SHOW lock_timeout;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;
SHOW deadlock_timeout;

-- Uji coba untuk mengubah lock_timeout menjadi 3 detik
SET lock_timeout = '3s';

-- Uji coba untuk mengubah statement_timeout menjadi 3 detik
SET statement_timeout = '3s';

-- Uji coba untuk mengubah idle_in_transaction_session_timeout menjadi 3 detik
SET idle_in_transaction_session_timeout = '3s';

-- Uji coba deadlock_timeout dan periksa nilainya
SHOW deadlock_timeout;