{{
  config(
    materialized = 'incremental'
  )
}}

WITH src_transactions AS (
    SELECT * 
    FROM {{ ref('src_transactions') }}
)
SELECT * 
FROM src_transactions
{% if is_incremental() %}
WHERE CREATED_AT > (SELECT MAX(CREATED_AT) FROM {{ this }})
{% endif %}