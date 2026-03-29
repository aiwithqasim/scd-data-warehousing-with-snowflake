-- =========================================================
-- MANUAL MERGE VALIDATION
-- =========================================================
MERGE INTO customer AS c
USING customer_raw AS cr
ON c.customer_id = cr.customer_id

WHEN MATCHED AND (
       c.first_name  <> cr.first_name  OR
       c.last_name   <> cr.last_name   OR
       c.email       <> cr.email       OR
       c.street      <> cr.street      OR
       c.city        <> cr.city        OR
       c.state       <> cr.state       OR
       c.country     <> cr.country
)
THEN UPDATE SET
       c.first_name       = cr.first_name,
       c.last_name        = cr.last_name,
       c.email            = cr.email,
       c.street           = cr.street,
       c.city             = cr.city,
       c.state            = cr.state,
       c.country          = cr.country,
       c.update_timestamp = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
INSERT (
       customer_id,
       first_name,
       last_name,
       email,
       street,
       city,
       state,
       country
)
VALUES (
       cr.customer_id,
       cr.first_name,
       cr.last_name,
       cr.email,
       cr.street,
       cr.city,
       cr.state,
       cr.country
);

-- Validate main table
SELECT * FROM customer;


-- =========================================================
-- PROCEDURE CREATION (MERGE + TRUNCATE)
-- =========================================================
CREATE OR REPLACE PROCEDURE pdr_scd_demo()
RETURNS STRING NOT NULL
LANGUAGE JAVASCRIPT
AS
$$
var merge_cmd = `
MERGE INTO customer AS c
USING customer_raw AS cr
ON c.customer_id = cr.customer_id

WHEN MATCHED AND (
       c.first_name <> cr.first_name OR
       c.last_name  <> cr.last_name  OR
       c.email      <> cr.email      OR
       c.street     <> cr.street     OR
       c.city       <> cr.city       OR
       c.state      <> cr.state      OR
       c.country    <> cr.country
)
THEN UPDATE SET
       c.first_name       = cr.first_name,
       c.last_name        = cr.last_name,
       c.email            = cr.email,
       c.street           = cr.street,
       c.city             = cr.city,
       c.state            = cr.state,
       c.country          = cr.country,
       c.update_timestamp = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
INSERT (
       customer_id,
       first_name,
       last_name,
       email,
       street,
       city,
       state,
       country
)
VALUES (
       cr.customer_id,
       cr.first_name,
       cr.last_name,
       cr.email,
       cr.street,
       cr.city,
       cr.state,
       cr.country
);
`;

var truncate_cmd = `TRUNCATE TABLE SCD_DEMO.SCD2.customer_raw;`;

// Execute MERGE
var stmt_merge = snowflake.createStatement({ sqlText: merge_cmd });
stmt_merge.execute();

// Truncate staging
var stmt_truncate = snowflake.createStatement({ sqlText: truncate_cmd });
stmt_truncate.execute();

return 'MERGE and TRUNCATE executed successfully';
$$;

-- Call the procedure and validate
CALL pdr_scd_demo();
SELECT * FROM customer;
SELECT * FROM customer_raw;


-- =========================================================
-- TASKADMIN ROLE CREATION & PRIVILEGES
-- =========================================================
-- Create role for managing tasks
USE ROLE SECURITYADMIN;
CREATE OR REPLACE ROLE taskadmin;

-- Grant execute task privilege
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE taskadmin;

-- Grant role to SYSADMIN
USE ROLE SECURITYADMIN;
GRANT ROLE taskadmin TO ROLE sysadmin;


-- =========================================================
-- TASK CREATION (Automated SCD Load)
-- =========================================================
CREATE OR REPLACE TASK tsk_scd_raw
  WAREHOUSE = compute_wh
  SCHEDULE = '1 MINUTE'
  ERROR_ON_NONDETERMINISTIC_MERGE = FALSE
AS
  CALL pdr_scd_demo();

-- Show tasks
SHOW TASKS;

-- Suspend task (default safe state)
ALTER TASK tsk_scd_raw SUSPEND;

-- Resume task later when ready
-- ALTER TASK tsk_scd_raw RESUME;

-- Show task details & next scheduled runs
SELECT 
    TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP, SCHEDULED_TIME) AS next_run,
    SCHEDULED_TIME,
    CURRENT_TIMESTAMP AS current_time,
    NAME,
    STATE
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'TSK_SCD_RAW',
        RESULT_LIMIT => 10
    )
)
WHERE STATE = 'SCHEDULED'
ORDER BY SCHEDULED_TIME DESC;

-- Quick validation
SELECT * FROM customer WHERE customer_id = 0;