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


