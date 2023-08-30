#!/bin/bash

glue_role_name=$(cat ../config_file.toml | grep 'glue_role_name' | awk -F"=" '{print $2}' | tr -d "'" | tr -d " ")
athena_db=$(cat ../config_file.toml | grep 'athena_db' | awk -F"=" '{print $2}' | tr -d "'" | tr -d " ")
s3_bucket_output=$(cat ../config_file.toml | grep 's3_bucket_output' | awk -F"=" '{print $2}' | tr -d "'" | tr -d " ")
aws_region=$(cat ../config_file.toml | grep 'region' | awk -F"=" '{print $2}' | tr -d "'" | tr -d " ")
glue_crawler_name=$(cat ../config_file.toml | grep 'glue_crawler_name' | awk -F"=" '{print $2}' | tr -d "'" | tr -d " ")

# Create a Glue crawler for each of the tables (calendar, fact, product, and store tables)
for table in calendar fact product store;
do 
aws glue create-crawler --name ${glue_crawler_name}_${table} \
 --role ${glue_role_name} \
 --targets S3Targets=[{Path="s3://${s3_bucket_output}/data/${table}"}]\
 --database-name ${athena_db} \
 --region ${aws_region} \
 --schedule "cron(0 10 * * ? *)" # Runs at 10am daily UTC, which is 6am EST, 1 hour after the Lambda function has been triggered
done;
