WITH transactions_with_store AS (
    SELECT
        FT.TRANSACTIONS_ID,
        TO_TIMESTAMP(FT.HAPPENED_AT, 'MM/DD/YYYY HH24:MI') AS HAPPENED_AT,
        DD.STORE_ID
    FROM {{ ref('fct_transactions') }} FT
    JOIN {{ ref('dim_device') }} DD
        ON FT.TRANSACTIONS_DEVICE_ID = DD.DEVICE_ID
    WHERE FT.TRANSACTIONS_STATUS = 'accepted'
),

ranked_transactions AS (
    SELECT
        STORE_ID,
        HAPPENED_AT,
        ROW_NUMBER() OVER (PARTITION BY STORE_ID ORDER BY HAPPENED_AT) AS RN
    FROM transactions_with_store
),

first_5_transactions AS (
    SELECT *
    FROM ranked_transactions
    WHERE RN <= 5
),

store_first_fifth_time AS (
    SELECT
        STORE_ID,
        MIN(HAPPENED_AT) AS FIRST_TRANSACTION_TIME,
        MAX(HAPPENED_AT) AS FIFTH_TRANSACTION_TIME,
        DATEDIFF('SECOND', MIN(HAPPENED_AT), MAX(HAPPENED_AT)) AS SECONDS_TO_5_TRANSACTIONS
    FROM first_5_transactions
    GROUP BY STORE_ID
    HAVING COUNT(*) = 5
)

SELECT
    DS.STORE_ID,
    DS.STORE_NAME,
    DS.STORE_COUNTRY,
    DS.STORE_TYPOLOGY,
    SFT.FIRST_TRANSACTION_TIME,
    SFT.FIFTH_TRANSACTION_TIME,
    ROUND(SFT.SECONDS_TO_5_TRANSACTIONS / 3600.0, 2) AS HOURS_TO_5_TRANSACTIONS
FROM store_first_fifth_time SFT
JOIN {{ ref('dim_store') }} DS
    ON SFT.STORE_ID = DS.STORE_ID
ORDER BY HOURS_TO_5_TRANSACTIONS DESC
