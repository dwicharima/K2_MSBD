WITH bulanan AS (
    SELECT 
        date_trunc('month', p.payment_date)::date AS bulan,
        c.name AS kategori,
        sum(p.amount) AS pendapatan
    FROM payment p
    JOIN rental r ON r.rental_id = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON fc.film_id = i.film_id
    JOIN category c ON c.category_id = fc.category_id
    GROUP BY 1, 2
)
SELECT 
    bulan,
    kategori,
    pendapatan,

    rank() OVER (
        PARTITION BY bulan
        ORDER BY pendapatan DESC
    ) AS peringkat,

    lag(pendapatan) OVER (
        PARTITION BY kategori
        ORDER BY bulan
    ) AS bulan_lalu,

    ROUND(
        (
            (pendapatan - lag(pendapatan) OVER (
                PARTITION BY kategori
                ORDER BY bulan
            ))
            / NULLIF(
                lag(pendapatan) OVER (
                    PARTITION BY kategori
                    ORDER BY bulan
                ),
                0
            )
        ) * 100,
        2
    ) AS pertumbuhan_persen,

    sum(pendapatan) OVER (
        PARTITION BY kategori
        ORDER BY bulan
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS pendapatan_kumulatif,

    ROUND(
        pendapatan * 100.0 /
        sum(pendapatan) OVER (
            PARTITION BY bulan
        ),
        2
    ) AS porsi_persen

FROM bulanan
ORDER BY bulan, peringkat;