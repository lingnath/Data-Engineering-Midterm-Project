-- Step 1: Create an integration and stage to connect the snowflake database to your own S3 bucket
use database midterm_db;
use schema raw;

create or replace STORAGE INTEGRATION s3_int_midterm
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{aws account id}:role/{role name for s3 snowflake integration}'
STORAGE_ALLOWED_LOCATIONS = ('s3://{input s3 bucket on config_file.toml}');

desc integration s3_int_midterm;

grant create stage on schema raw to role accountadmin;
grant usage on integration s3_int_midterm to role accountadmin;

create or replace file format csv_comma
type = 'CSV'
field_delimiter = ',';

create or replace stage wcd_de_midterm_load_to_s3_stage
STORAGE_INTEGRATION = s3_int_midterm
file_format = csv_comma
url = 's3://{input s3 bucket on config_file.toml}/';

list @wcd_de_midterm_load_to_s3_stage;

-- Step 2: Create a procedure to load data from Snowflake table to S3.
CREATE OR REPLACE PROCEDURE COPY_INTO_S3()
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
    var rows = [];
    var stage_name = "wcd_de_midterm_load_to_s3_stage";
    var n = new Date();
    // May need refinement to zero-pad some values or achieve a specific format
    var date = `${n.getFullYear()}-${("0" + (n.getMonth() + 1)).slice(-2)}-${("0" + (n.getDate())).slice(-2)}`;

    var st_inv = snowflake.createStatement({
        sqlText: `COPY INTO '@${stage_name}/data/inventory_${date}.csv' FROM (select * from midterm_db.raw.inventory where cal_dt <= current_date()) file_format=(NULL_IF=(), TYPE=CSV, COMPRESSION='None') SINGLE=TRUE HEADER=TRUE MAX_FILE_SIZE=107772160 OVERWRITE=TRUE;`
    });
    var st_sales = snowflake.createStatement({
        sqlText: `COPY INTO '@${stage_name}/data/sales_${date}.csv' FROM (select * from midterm_db.raw.sales where trans_dt <= current_date()) file_format=(NULL_IF=(), TYPE=CSV, COMPRESSION='None') SINGLE=TRUE HEADER=TRUE MAX_FILE_SIZE=107772160 OVERWRITE=TRUE;`
    });
    var st_store = snowflake.createStatement({
        sqlText: `COPY INTO '@${stage_name}/data/store_${date}.csv' FROM (select * from midterm_db.raw.store) file_format=(NULL_IF=(), TYPE=CSV, COMPRESSION='None') SINGLE=TRUE HEADER=TRUE MAX_FILE_SIZE=107772160 OVERWRITE=TRUE;`
    });
    var st_product = snowflake.createStatement({
        sqlText: `COPY INTO '@${stage_name}/data/product_${date}.csv' FROM (select * from midterm_db.raw.product) file_format=(NULL_IF=(), TYPE=CSV, COMPRESSION='None') SINGLE=TRUE HEADER=TRUE MAX_FILE_SIZE=107772160 OVERWRITE=TRUE;`
    });
    var st_calendar = snowflake.createStatement({
        sqlText: `COPY INTO '@${stage_name}/data/calendar_${date}.csv' FROM (select * from midterm_db.raw.calendar) file_format=(NULL_IF=(), TYPE=CSV, COMPRESSION='None') SINGLE=TRUE HEADER=TRUE MAX_FILE_SIZE=107772160 OVERWRITE=TRUE;`
    });

    var result_inv = st_inv.execute();
    var result_sales = st_sales.execute();
    var result_store = st_store.execute();
    var result_product = st_product.execute();
    var result_calendar = st_calendar.execute();


    result_inv.next();
    result_sales.next();
    result_store.next();
    result_product.next();
    result_calendar.next();

    rows.push(result_inv.getColumnValue(1))
    rows.push(result_sales.getColumnValue(1))
    rows.push(result_store.getColumnValue(1))
    rows.push(result_product.getColumnValue(1))
    rows.push(result_calendar.getColumnValue(1))


    return rows;
$$;


-- Step 3: Create a task to run the job. Here we use cron to set job at 4am EST everyday.
-- I chose to run this task at 4am EST as I live in PST. I want to ensure when this task runs, it is
-- the following day in my timezone so that the csv file in S3 is properly named. This is important 
-- as the Lambda function will not be able to call the Airflow API if the csv file name is a day behind.
CREATE OR REPLACE TASK load_data_to_s3
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON 0 4 * * * America/New_York'
AS
CALL COPY_INTO_S3();

-- Step 4: Activate the task
ALTER TASK load_data_to_s3 resume;

-- Step 5: Check if the task state is 'started'
DESCRIBE TASK load_data_to_s3;

-- Step 6: Deactivate the task
DROP TASK load_data_to_s3;
