# Introduction and Environment Setup

## How to figure out my Snowflake Account URL?
The easiest is to take a look at your Snowflake Registration email and copy the string before `.snowflakecomputing.com`. In my case this is `frgcsyo-ie17820`. Keep in mind that sometimes urls include the `.aws` tag, too, such as `frgcsyo-ie17820.aws`. This isn't simple, I know. Even _dbt Labs_ [has it's own section](https://docs.getdbt.com/docs/cloud/connect-data-platform/connect-snowflake) on how to figure it out.

<img width="980" alt="Screenshot 2024-10-21 at 10 36 03" src="https://github.com/user-attachments/assets/54faccde-5b57-413d-8e7c-2d5bbea5585a">

## Fast track the Snowflake Setup
If you want to skip the manual user creation and raw table import, we've created an auto-importer for you. 
Take a look at https://dbt-data-importer.streamlit.app/ where we set up Snowflake for you with a click of a button!


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
. venv/bin/activate
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
