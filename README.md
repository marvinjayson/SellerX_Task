# Introduction and Environment Setup

<img width="980" alt="Screenshot 2024-10-21 at 10 36 03" src="https://github.com/user-attachments/assets/54faccde-5b57-413d-8e7c-2d5bbea5585a">

## Snowflake user creation
Copy these SQL statements into a Snowflake Worksheet, select all and execute them (i.e. pressing the play button).

If you see a _Grant partially executed: privileges [REFERENCE_USAGE] not granted._ message when you execute `GRANT ALL ON DATABASE AIRBNB to ROLE transform`, that's just an info message and you can ignore it. 

```sql {#snowflake_setup}
-- Use an admin role
USE ROLE ACCOUNTADMIN;

-- Create the `transform` role
CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Create the default warehouse if necessary
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

-- Create the `dbt` user and assign to role
CREATE USER IF NOT EXISTS dbt
  PASSWORD='dbtPassword123'
  LOGIN_NAME='dbt'
  MUST_CHANGE_PASSWORD=FALSE
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_ROLE=TRANSFORM
  DEFAULT_NAMESPACE='SELLERX.RAW'
  COMMENT='DBT user used for data transformation';
ALTER USER dbt SET TYPE = LEGACY_SERVICE;
GRANT ROLE TRANSFORM to USER dbt;

-- Create our database and schemas
CREATE DATABASE IF NOT EXISTS SELLERX;
CREATE SCHEMA IF NOT EXISTS SELLERX.RAW;

-- Set up permissions to role `transform`
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;
GRANT ALL ON DATABASE SELLERX to ROLE TRANSFORM;
GRANT ALL ON ALL SCHEMAS IN DATABASE SELLERX to ROLE TRANSFORM;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE SELLERX to ROLE TRANSFORM;
GRANT ALL ON ALL TABLES IN SCHEMA SELLERX.RAW to ROLE TRANSFORM;
GRANT ALL ON FUTURE TABLES IN SCHEMA SELLERX.RAW to ROLE TRANSFORM;

CREATE SCHEMA IF NOT EXISTS SELLERX.STAGE;
CREATE STAGE IF NOT EXISTS SELLERX.STAGE.DEVICE_STAGE;
CREATE STAGE IF NOT EXISTS SELLERX.STAGE.STORE_STAGE;
CREATE STAGE IF NOT EXISTS SELLERX.STAGE.TRANSACTION_STAGE;
```

## Snowflake data upload

Copy these SQL statements into a Snowflake Worksheet, select all and execute them (i.e. pressing the play button).

```sql {#snowflake_stages}

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE SELLERX;
USE SCHEMA SELLERX.RAW;

CREATE TABLE IF NOT EXISTS SELLERX.RAW.RAW_STORE (
    ID           STRING,
    NAME         STRING,
    ADDRESS      STRING,
    CITY         STRING,
    COUNTRY      STRING,
    CREATED_AT   TIMESTAMP_NTZ,
    TYPOLOGY     STRING,
    CUSTOMER_ID  STRING
);

CREATE TABLE IF NOT EXISTS SELLERX.RAW.RAW_TRANSACTIONS (
    ID             STRING,
    DEVICE_ID      STRING,
    PRODUCT_NAME   STRING,
    PRODUCT_SKU    STRING,
    AMOUNT         NUMBER(18, 2),
    STATUS         STRING,
    CARD_NUMBER    STRING,
    CVV            STRING,
    CREATED_AT     TIMESTAMP_NTZ,
    HAPPENED_AT    TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS SELLERX.RAW.RAW_DEVICE (
    ID        STRING,
    TYPE      STRING,
    STORE_ID  STRING
);

COPY INTO SELLERX.RAW.RAW_DEVICE
FROM @SELLERX.STAGE.DEVICE_STAGE/device.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
FORCE = TRUE;

COPY INTO SELLERX.RAW.RAW_TRANSACTIONS
FROM @SELLERX.STAGE.TRANSACTION_STAGE/transaction.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
FORCE = TRUE;


COPY INTO SELLERX.RAW.RAW_STORE
FROM @SELLERX.STAGE.STORE_STAGE/store.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE'
FORCE = TRUE;
```

# Python and Virtualenv setup, and dbt installation - Windows

## Python
This is the Python installer you want to use: 

[https://www.python.org/ftp/python/3.10.7/python-3.10.7-amd64.exe ](https://www.python.org/downloads/release/python-3113/)

Please make sure that you work with Python 3.11 as newer versions of python might not be compatible with some of the dbt packages.

## Virtualenv setup
Here are the commands i executed in this task:
```

C:\SellerX_Task>
dir SellerX_Task
cd SellerX
virtualenv venv
venv\Scripts\activate
```

## dbt installation

Here are the commands i execute in this task:

```cmd or vscode terminal

pip install dbt-snowflake==1.9.0

```
# Models
### SRC Device 
`models/src/src_device.sql`:

```sql
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

```

### SRC Store
`models/src/src_store.sql`:

```sql
{{
  config(
    materialized = 'ephemeral'
    )
}}

WITH raw_store AS (
    SELECT
        *
    FROM
        SELLERX.RAW.RAW_STORE
)
SELECT
    ID AS STORE_ID,
	NAME AS STORE_NAME,
	CUSTOMER_ID AS STORE_CUSTOMER_ID,
    ADDRESS AS STORE_ADDRESS,
	CITY AS STORE_CITY,
	COUNTRY STORE_COUNTRY,
	TYPOLOGY AS STORE_TYPOLOGY,
	CREATED_AT	
FROM
    raw_store
```

### SRC Transactions
`models/src/src_transactions.sql`:

```sql
{{
  config(
    materialized = 'ephemeral'
    )
}}

WITH raw_transactions AS (
    SELECT
        *
    FROM
        SELLERX.RAW.RAW_TRANSACTIONS
)
SELECT
    ID AS TRANSACTIONS_ID,
	DEVICE_ID AS TRANSACTIONS_DEVICE_ID,
	PRODUCT_NAME AS TRANSACTIONS_PRODUCT_NAME,
	PRODUCT_SKU AS TRANSACTIONS_PRODUCT_SKU,
	PRODUCT_NAME2 AS TRANSACTIONS_PRODUCT_NAME2,
	AMOUNT AS TRANSACTIONS_AMOUNT,
	STATUS AS TRANSACTIONS_STATUS,
	CARD_NUMBER AS TRANSACTIONS_CARD_NUMBER,
	CVV AS TRANSACTIONS_CVV,
	CREATED_AT,
	HAPPENED_AT	
FROM
    raw_transactions
```
### DIM Device
`models/dim/dim_device.sql`:

```sql
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

```
### DIM Store
`models/dim/dim_store.sql`:

```sql
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
```
### Fct Trasactions
`models/fct/fct_transactions.sql`:

```sql{{
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
```
# DataMart as my final model to meet this criteria:
## • Top 10 stores per transacted amount
## • Top 10 products sold
## • Average transacted amount per store typology and country
## • Percentage of transactions per device type
## • Average time for a store to perform its 5 first transactions

`models/mart/master_device_store_transactions.sql`:

```sql{{
{{
  config(
    materialized = 'table'
  )
}}

WITH fct_transactions AS (
    SELECT *
    FROM {{ ref('fct_transactions') }}
    WHERE TRANSACTIONS_STATUS = 'accepted'
),

dim_device AS (
    SELECT *
    FROM {{ ref('dim_device') }}
),

dim_store AS (
    SELECT *
    FROM {{ ref('dim_store') }}
),

joined_data AS (
    SELECT
        FT.*,
        DD.DEVICE_ID,
        DD.DEVICE_TYPE,
        DD.STORE_ID AS DEVICE_STORE_ID,
        DS.STORE_NAME,
        DS.STORE_CUSTOMER_ID,
        DS.STORE_ADDRESS,
        DS.STORE_CITY,
        DS.STORE_COUNTRY,
        DS.STORE_TYPOLOGY,
        DS.CREATED_AT AS STORE_CREATED_AT,
        TO_TIMESTAMP(FT.HAPPENED_AT, 'MM/DD/YYYY HH24:MI') AS HAPPENED_AT_TS
    FROM fct_transactions FT
    JOIN dim_device DD ON FT.TRANSACTIONS_DEVICE_ID = DD.DEVICE_ID
    JOIN dim_store DS ON DD.STORE_ID = DS.STORE_ID
),

store_totals AS (
    SELECT
        STORE_NAME,
        SUM(TRANSACTIONS_AMOUNT) AS TOTAL_TRANSACTED_AMOUNT
    FROM joined_data
    GROUP BY STORE_NAME
),

product2_counts AS (
    SELECT
        TRANSACTIONS_PRODUCT_NAME2,
        COUNT(*) AS PRODUCT2_SOLD_COUNT
    FROM joined_data
    GROUP BY TRANSACTIONS_PRODUCT_NAME2
),

store_avg_amount AS (
    SELECT
        STORE_NAME,
        ROUND(AVG(TRANSACTIONS_AMOUNT), 2) AS AVG_TRANSACTION_AMOUNT
    FROM joined_data
    GROUP BY STORE_NAME
),

device_type_distribution AS (
    SELECT
        DEVICE_TYPE,
        COUNT(*) AS TOTAL_BY_DEVICE,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS DEVICE_TRANSACTION_PERCENT
    FROM joined_data
    GROUP BY DEVICE_TYPE
),

ranked_txn AS (
    SELECT
        STORE_NAME,
        HAPPENED_AT_TS,
        ROW_NUMBER() OVER (PARTITION BY STORE_NAME ORDER BY HAPPENED_AT_TS) AS RN
    FROM joined_data
),

first_5_txn AS (
    SELECT * FROM ranked_txn WHERE RN <= 5
),

store_time_to_5 AS (
    SELECT
        STORE_NAME,
        ROUND(DATEDIFF('SECOND', MIN(HAPPENED_AT_TS), MAX(HAPPENED_AT_TS)) / 3600.0, 2) AS HOURS_TO_5_TRANSACTIONS
    FROM first_5_txn
    GROUP BY STORE_NAME
    HAVING COUNT(*) = 5
)

SELECT
    JD.TRANSACTIONS_ID,
    JD.TRANSACTIONS_PRODUCT_NAME,
    JD.TRANSACTIONS_PRODUCT_NAME2,
    JD.TRANSACTIONS_PRODUCT_SKU,
    JD.TRANSACTIONS_AMOUNT,
    JD.TRANSACTIONS_STATUS,
    JD.TRANSACTIONS_CARD_NUMBER,
    JD.TRANSACTIONS_CVV,
    JD.CREATED_AT AS TRANSACTION_CREATED_AT,
    JD.HAPPENED_AT,

    JD.DEVICE_ID,
    JD.DEVICE_TYPE,
    DTD.DEVICE_TRANSACTION_PERCENT,

    JD.STORE_NAME,
    JD.STORE_COUNTRY,
    JD.STORE_TYPOLOGY,
    JD.STORE_ADDRESS,
    JD.STORE_CITY,
    JD.STORE_CUSTOMER_ID,
    JD.STORE_CREATED_AT,

    ST.TOTAL_TRANSACTED_AMOUNT,
    SA.AVG_TRANSACTION_AMOUNT,
    PC.PRODUCT2_SOLD_COUNT,
    STT.HOURS_TO_5_TRANSACTIONS

FROM joined_data JD
LEFT JOIN store_totals ST ON JD.STORE_NAME = ST.STORE_NAME
LEFT JOIN store_avg_amount SA ON JD.STORE_NAME = SA.STORE_NAME
LEFT JOIN product2_counts PC ON JD.TRANSACTIONS_PRODUCT_NAME2 = PC.TRANSACTIONS_PRODUCT_NAME2
LEFT JOIN device_type_distribution DTD ON JD.DEVICE_TYPE = DTD.DEVICE_TYPE
LEFT JOIN store_time_to_5 STT ON JD.STORE_NAME = STT.STORE_NAME
