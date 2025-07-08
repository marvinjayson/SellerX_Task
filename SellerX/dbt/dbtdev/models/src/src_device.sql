{{
  config(
    materialized = 'ephemeral'
    )
}}

WITH raw_device AS (
    SELECT
        *
    FROM
        SELLERX.RAW.RAW_DEVICE
)
SELECT
    ID AS DEVICE_ID,
	TYPE AS DEVICE_TYPE,
	STORE_ID

FROM
    raw_device