-- =========================================================
-- Warehouse Setup
-- =========================================================
USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS compute_wh
WITH 
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 120;

-- =========================================================
-- Database & Schema Setup
-- =========================================================
CREATE DATABASE IF NOT EXISTS scd_demo;
USE DATABASE scd_demo;

CREATE SCHEMA IF NOT EXISTS scd2;
USE SCHEMA scd2;

-- =========================================================
-- Validation
-- =========================================================
SHOW TABLES;

SELECT CURRENT_TIMESTAMP();

-- =========================================================
-- Table Creation
-- =========================================================

-- Base table (source of truth)
CREATE OR REPLACE TABLE customer (
    customer_id      NUMBER,
    first_name       VARCHAR,
    last_name        VARCHAR,
    email            VARCHAR,
    street           VARCHAR,
    city             VARCHAR,
    state            VARCHAR,
    country          VARCHAR,
    update_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- SCD Type 2 history table
CREATE OR REPLACE TABLE customer_history (
    customer_id  NUMBER,
    first_name   VARCHAR,
    last_name    VARCHAR,
    email        VARCHAR,
    street       VARCHAR,
    city         VARCHAR,
    state        VARCHAR,
    country      VARCHAR,
    start_time   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    end_time     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    is_current   BOOLEAN
);

-- Staging / raw ingestion table
CREATE OR REPLACE TABLE customer_raw (
    customer_id NUMBER,
    first_name  VARCHAR,
    last_name   VARCHAR,
    email       VARCHAR,
    street      VARCHAR,
    city        VARCHAR,
    state       VARCHAR,
    country     VARCHAR
);

-- =========================================================
-- Stream (CDC)
-- =========================================================
CREATE OR REPLACE STREAM customer_table_changes 
ON TABLE customer;
