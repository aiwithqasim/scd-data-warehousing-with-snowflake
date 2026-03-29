-- =========================================================
-- METHOD 1: Direct Stage Using AWS Access Keys
-- =========================================================
CREATE OR REPLACE STAGE customer_ext_stage
  URL = 's3://scd-demo/'
  CREDENTIALS = (
      AWS_KEY_ID = '<access-key>'
      AWS_SECRET_KEY = '<secret-key>'
  )
  FILE_FORMAT = CSV;

-- Validate stage
SHOW STAGES;
LIST @customer_ext_stage;


-- =========================================================
-- METHOD 2: Using Storage Integration (Recommended)
-- =========================================================

-- Grant privileges for creating storage integration
USE ROLE ACCOUNTADMIN;
GRANT CREATE INTEGRATION ON ACCOUNT TO SYSADMIN;

USE ROLE SYSADMIN;

-- Create storage integration to S3
CREATE OR REPLACE STORAGE INTEGRATION s3_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<account-number>:role/role-scd-warehousing-us-west-2-qhn'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://s3-scd-warehousing-us-west-2-qhn');

-- Validate integration
DESC INTEGRATION s3_integration;


-- Create stage using storage integration
CREATE OR REPLACE STAGE s3_integration_bulk_copy_scd_warehouse
  STORAGE_INTEGRATION = s3_integration
  URL = 's3://s3-scd-warehousing-us-west-2-qhn/'
  FILE_FORMAT = (
      TYPE = 'CSV',
      FIELD_DELIMITER = ',',
      SKIP_HEADER = 1
  );

-- Validate stage
LIST @s3_integration_bulk_copy_scd_warehouse;


-- =========================================================
-- Snowpipe Creation for Auto-Ingest
-- =========================================================
CREATE OR REPLACE PIPE customer_s3_pipe
  AUTO_INGEST = TRUE
AS
  COPY INTO customer_raw
  FROM @s3_integration_bulk_copy_scd_warehouse/;

-- Validate Snowpipe
SHOW PIPES;
DESC PIPE customer_s3_pipe;
SELECT SYSTEM$PIPE_STATUS('customer_s3_pipe');


-- =========================================================
-- Validate Data After Load
-- =========================================================
SELECT COUNT(*) FROM customer_raw;
SELECT * FROM customer_raw LIMIT 10;