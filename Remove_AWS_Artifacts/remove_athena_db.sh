#!/bin/bash

athena_db=$(cat ../config_file.toml | grep 'athena_db' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
region=$(cat ../config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
s3_bucket_output=$(cat ../config_file.toml | grep 's3_bucket_output' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Remove athena database for this project
aws glue delete-database --name ${athena_db} \
 --region ${region}
