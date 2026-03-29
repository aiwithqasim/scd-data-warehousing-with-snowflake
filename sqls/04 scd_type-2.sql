-- =========================================================
-- Case creation for insert, update and delete
-- =========================================================

-- Check available streams
SHOW STREAMS;

-- View stream data (change data capture)
SELECT * FROM customer_table_changes;

-- Insert new record
INSERT INTO customer (
    customer_id,
    first_name,
    last_name,
    email,
    street,
    city,
    state,
    country,
    update_timestamp
)
VALUES (
    223136,
    'Jessica',
    'Arnold',
    'tanner39@smith.com',
    '595 Benjamin Forge Suite 124',
    'Michaelstad',
    'Connecticut',
    'Cape Verde',
    CURRENT_TIMESTAMP()
);

-- Update existing record
UPDATE customer
SET 
    first_name = 'Jessica',
    update_timestamp = CURRENT_TIMESTAMP()::TIMESTAMP_NTZ
WHERE customer_id = 72;

-- Delete record
DELETE FROM customer
WHERE customer_id = 73;

-- Check history table (SCD / audit)
SELECT * 
FROM customer_history
WHERE customer_id IN (72, 73, 223136);

-- Check stream again after DML
SELECT * 
FROM customer_table_changes;

-- Verify current state of base table
SELECT * 
FROM customer
WHERE customer_id IN (72, 73, 223136);

-- =========================================================
-- View creation for change capturing
-- =========================================================

CREATE OR REPLACE VIEW v_customer_change_data AS

-- 1. INSERT handling (pure inserts into base table)
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    street,
    city,
    state,
    country,
    start_time,
    end_time,
    is_current,
    'I' AS dml_type
FROM (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        street,
        city,
        state,
        country,
        update_timestamp AS start_time,
        LAG(update_timestamp) OVER (
            PARTITION BY customer_id 
            ORDER BY update_timestamp DESC
        ) AS end_time_raw,
        CASE 
            WHEN end_time_raw IS NULL THEN '9999-12-31'::TIMESTAMP_NTZ 
            ELSE end_time_raw 
        END AS end_time,
        CASE 
            WHEN end_time_raw IS NULL THEN TRUE 
            ELSE FALSE 
        END AS is_current
    FROM (
        SELECT 
            customer_id,
            first_name,
            last_name,
            email,
            street,
            city,
            state,
            country,
            update_timestamp
        FROM SCD_DEMO.SCD2.customer_table_changes
        WHERE metadata$action = 'INSERT'
          AND metadata$isupdate = 'FALSE'
    )
)

UNION

-- 2. UPDATE handling (insert new + update old record)
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    street,
    city,
    state,
    country,
    start_time,
    end_time,
    is_current,
    dml_type
FROM (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        street,
        city,
        state,
        country,
        update_timestamp AS start_time,
        LAG(update_timestamp) OVER (
            PARTITION BY customer_id 
            ORDER BY update_timestamp DESC
        ) AS end_time_raw,
        CASE 
            WHEN end_time_raw IS NULL THEN '9999-12-31'::TIMESTAMP_NTZ 
            ELSE end_time_raw 
        END AS end_time,
        CASE 
            WHEN end_time_raw IS NULL THEN TRUE 
            ELSE FALSE 
        END AS is_current,
        dml_type
    FROM (
        -- New version of updated row (INSERT into history)
        SELECT 
            customer_id,
            first_name,
            last_name,
            email,
            street,
            city,
            state,
            country,
            update_timestamp,
            'I' AS dml_type
        FROM customer_table_changes
        WHERE metadata$action = 'INSERT'
          AND metadata$isupdate = 'TRUE'

        UNION

        -- Expire old record (UPDATE in history)
        SELECT 
            customer_id,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            start_time,
            'U' AS dml_type
        FROM customer_history
        WHERE customer_id IN (
            SELECT DISTINCT customer_id
            FROM customer_table_changes
            WHERE metadata$action = 'DELETE'
              AND metadata$isupdate = 'TRUE'
        )
          AND is_current = TRUE
    )
)

UNION

-- 3. DELETE handling (expire current record)
SELECT 
    ctc.customer_id,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    ch.start_time,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS end_time,
    NULL AS is_current,
    'D' AS dml_type
FROM customer_history ch
JOIN customer_table_changes ctc
    ON ch.customer_id = ctc.customer_id
WHERE ctc.metadata$action = 'DELETE'
  AND ctc.metadata$isupdate = 'FALSE'
  AND ch.is_current = TRUE;

-- Preview change data from the view
SELECT * 
FROM v_customer_change_data;

-- =========================================================
-- Task to load SCD Type 2 history table
-- =========================================================
CREATE OR REPLACE TASK tsk_scd_hist
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = '1 MINUTE'
  ERROR_ON_NONDETERMINISTIC_MERGE = FALSE
AS

MERGE INTO customer_history AS ch
USING v_customer_change_data AS ccd
ON  ch.customer_id = ccd.customer_id
AND ch.start_time  = ccd.start_time

-- Expire old record (UPDATE case)
WHEN MATCHED AND ccd.dml_type = 'U' THEN
UPDATE SET
    ch.end_time   = ccd.end_time,
    ch.is_current = FALSE

-- Logical delete (DELETE case)
WHEN MATCHED AND ccd.dml_type = 'D' THEN
UPDATE SET
    ch.end_time   = ccd.end_time,
    ch.is_current = FALSE

-- Insert new record (INSERT + UPDATE new version)
WHEN NOT MATCHED AND ccd.dml_type = 'I' THEN
INSERT (
    customer_id,
    first_name,
    last_name,
    email,
    street,
    city,
    state,
    country,
    start_time,
    end_time,
    is_current
)
VALUES (
    ccd.customer_id,
    ccd.first_name,
    ccd.last_name,
    ccd.email,
    ccd.street,
    ccd.city,
    ccd.state,
    ccd.country,
    ccd.start_time,
    ccd.end_time,
    ccd.is_current
);

-- Check tasks
SHOW TASKS;

-- Suspend task (created in suspended state by default anyway)
ALTER TASK tsk_scd_hist SUSPEND;

-- To run it:
-- ALTER TASK tsk_scd_hist RESUME;

-- =========================================================
-- DML Operations (trigger CDC → Stream → SCD pipeline)
-- =========================================================

-- Insert new customer
INSERT INTO customer
VALUES (
    223136,
    'Jessica',
    'Arnold',
    'tanner39@smith.com',
    '595 Benjamin Forge Suite 124',
    'Michaelstad',
    'Connecticut',
    'Cape Verde',
    CURRENT_TIMESTAMP()
);

-- Update customer (check if ID exists)
UPDATE customer
SET first_name = 'Jessica'
WHERE customer_id = 7523;

-- Delete specific customer
DELETE FROM customer
WHERE customer_id = 136
  AND first_name = 'Kim';


-- =========================================================
-- Data Validation Queries
-- =========================================================

-- Check for duplicates (should NOT exist ideally)
SELECT 
    customer_id,
    COUNT(*) AS record_count
FROM customer
GROUP BY customer_id
HAVING COUNT(*) = 1;

-- Check history for specific customer
SELECT * 
FROM customer_history
WHERE customer_id = 223136;

-- Check current active records (SCD Type 2 current rows)
SELECT * 
FROM customer_history
WHERE is_current = TRUE;

-- Check expired records
SELECT * 
FROM customer_history
WHERE is_current = FALSE;


-- =========================================================
-- Task Monitoring
-- =========================================================

-- Check next scheduled task runs
SELECT 
    TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP, SCHEDULED_TIME) AS next_run,
    SCHEDULED_TIME,
    CURRENT_TIMESTAMP AS current_time,
    NAME,
    STATE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE STATE = 'SCHEDULED'
ORDER BY SCHEDULED_TIME DESC;

-- List all tasks
SHOW TASKS;