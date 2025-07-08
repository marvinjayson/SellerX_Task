{{
  config(
    materialized = 'incremental'
    )
}}

WITH src_store AS (
    SELECT
        *
    FROM
        {{ ref('src_store') }}
)
SELECT * 
FROM src_store
{% if is_incremental() %}
WHERE CREATED_AT > (SELECT MAX(CREATED_AT) FROM {{ this }})
{% endif %}