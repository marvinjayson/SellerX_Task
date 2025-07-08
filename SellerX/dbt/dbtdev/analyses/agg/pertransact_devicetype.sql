WITH accepted_transactions AS (
    SELECT
        TRANSACTIONS_ID,
        TRANSACTIONS_DEVICE_ID
    FROM {{ ref('fct_transactions') }}
    WHERE TRANSACTIONS_STATUS = 'accepted'
),

transactions_with_device_type AS (
    SELECT
        AT.TRANSACTIONS_ID,
        DD.DEVICE_TYPE
    FROM accepted_transactions AT
    JOIN {{ ref('dim_device') }} DD
        ON AT.TRANSACTIONS_DEVICE_ID = DD.DEVICE_ID
),

transactions_grouped AS (
    SELECT
        DEVICE_TYPE,
        COUNT(TRANSACTIONS_ID) AS TOTAL_TRANSACTIONS
    FROM transactions_with_device_type
    GROUP BY DEVICE_TYPE
),

total_transactions AS (
    SELECT SUM(TOTAL_TRANSACTIONS) AS GRAND_TOTAL
    FROM transactions_grouped
)

SELECT
    TG.DEVICE_TYPE,
    ROUND(TG.TOTAL_TRANSACTIONS * 100.0 / TT.GRAND_TOTAL, 2) AS TRANSACTION_PERCENTAGE
FROM transactions_grouped TG
CROSS JOIN total_transactions TT
ORDER BY TRANSACTION_PERCENTAGE DESC
