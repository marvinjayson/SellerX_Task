WITH filtered_transactions AS (
    SELECT
        TRANSACTIONS_DEVICE_ID,
        TRANSACTIONS_AMOUNT
    FROM {{ ref('fct_transactions') }}
    WHERE TRANSACTIONS_STATUS = 'accepted'
),

device_store_map AS (
    SELECT
        DD.DEVICE_ID,
        DS.STORE_ID,
        DS.STORE_TYPOLOGY,
        DS.STORE_COUNTRY
    FROM {{ ref('dim_device') }} DD
    JOIN {{ ref('dim_store') }} DS
        ON DD.STORE_ID = DS.STORE_ID
),

transactions_with_store_info AS (
    SELECT
        DSM.STORE_TYPOLOGY,
        DSM.STORE_COUNTRY,
        FT.TRANSACTIONS_AMOUNT
    FROM filtered_transactions FT
    JOIN device_store_map DSM
        ON FT.TRANSACTIONS_DEVICE_ID = DSM.DEVICE_ID
)

SELECT
    STORE_TYPOLOGY,
    STORE_COUNTRY,
    ROUND(AVG(TRANSACTIONS_AMOUNT), 2) AS AVERAGE_TRANSACTION_AMOUNT
FROM transactions_with_store_info
GROUP BY
    STORE_TYPOLOGY,
    STORE_COUNTRY
ORDER BY
    AVERAGE_TRANSACTION_AMOUNT DESC