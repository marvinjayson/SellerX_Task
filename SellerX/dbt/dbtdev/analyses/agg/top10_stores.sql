WITH device AS (
    SELECT
        DEVICE_ID,
        STORE_ID
    FROM
        {{ ref('dim_device') }}
),

store AS (
    SELECT
        STORE_ID,
        STORE_NAME
    FROM
        {{ ref('dim_store') }}
),

transaction AS (
    SELECT
        TRANSACTIONS_DEVICE_ID,
        TRANSACTIONS_AMOUNT,
        TRANSACTIONS_STATUS
    FROM
        {{ ref('fct_transactions') }}
    WHERE
        TRANSACTIONS_STATUS = 'accepted'
),

store_sales AS (
    SELECT
        s.STORE_ID,
        s.STORE_NAME,
        SUM(t.TRANSACTIONS_AMOUNT) AS TOTAL_TRANSACTED_AMOUNT
    FROM
        transaction t
    JOIN device d ON t.TRANSACTIONS_DEVICE_ID = d.DEVICE_ID
    JOIN store s ON d.STORE_ID = s.STORE_ID
    GROUP BY
        s.STORE_ID, s.STORE_NAME
)

SELECT
    STORE_ID,
    STORE_NAME,
    TOTAL_TRANSACTED_AMOUNT
FROM
    store_sales
ORDER BY
    TOTAL_TRANSACTED_AMOUNT DESC
LIMIT 10
