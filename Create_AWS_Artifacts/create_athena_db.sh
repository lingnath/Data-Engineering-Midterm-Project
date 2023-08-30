#!/bin/bash

athena_db=$(cat ../config_file.toml | grep 'athena_db' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
region=$(cat ../config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
s3_bucket_output=$(cat ../config_file.toml | grep 's3_bucket_output' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Creates the database in Athena for this project
aws athena start-query-execution --query-string "CREATE database ${athena_db}" \
 --region ${region} \
 --result-configuration "OutputLocation=s3://${s3_bucket_output}/athena_metadata/"
