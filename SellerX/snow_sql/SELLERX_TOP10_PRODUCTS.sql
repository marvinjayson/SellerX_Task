USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE SELLERX;
USE SCHEMA SELLERX.DEV;

SELECT 
    TRANSACTIONS_PRODUCT_NAME2,
    COUNT(*) AS TOTAL_SOLD
FROM 
    SELLERX.DEV.FCT_TRANSACTIONS
WHERE 
    TRANSACTIONS_STATUS = 'accepted'
GROUP BY 
    TRANSACTIONS_PRODUCT_NAME2
ORDER BY 
    TOTAL_SOLD DESC
LIMIT 10;
