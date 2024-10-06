create or replace stage customer_ext_stage
  url='s3://scd-demo/'
  credentials=(aws_key_id='<access-key>' aws_secret_key='<secret-key>')
  file_format = CSV;
  
show stages;
list @customer_ext_stage;


create or replace pipe customer_s3_pipe
  auto_ingest = true
  as
  copy into customer_raw
  from @customer_ext_stage/customer_20210806183233.csv
  file_format = CSV
  ;
  
show pipes;
select SYSTEM$PIPE_STATUS('customer_s3_pipe');

select count(*) from customer_raw;



