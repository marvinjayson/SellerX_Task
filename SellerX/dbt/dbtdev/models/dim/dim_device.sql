{{
  config(
    materialized = 'incremental',
    unique_key = 'DEVICE_ID'
  )
}}

SELECT
    DEVICE_ID,
    DEVICE_TYPE,
    STORE_ID
FROM {{ ref('src_device') }}
