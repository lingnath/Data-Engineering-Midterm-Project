#!/bin/bash

function_name=$(cat ../config_file.toml | grep 'lambda_function_name' | awk -F"=" '{print $2}' | tr -d "'")
input_s3_bucket=$(cat ../config_file.toml | grep 's3_bucket_input_and_script' | awk -F"=" '{print $2}' | tr -d "'")
lambda_role_name=$(cat ../config_file.toml | grep 'lambda_role_name' | awk -F"=" '{print $2}' | tr -d "'")
region=$(cat ../config_file.toml | grep 'region' | awk -F"=" '{print $2}' | tr -d "'")
account_id=$(cat ../config_file.toml | grep 'account_id' | awk -F"=" '{print $2}' | tr -d "'")
lambda_layer_name=$(cat ../config_file.toml | grep 'lambda_layer_name' | awk -F"=" '{print $2}' | tr -d "'")
lambda_layer_version=$(cat ../config_file.toml | grep 'lambda_layer_version' | awk -F"=" '{print $2}' | tr -d "'")

# Zipping all code (includes the python script, config toml, and .env files)
zip lambda_code.zip lambda_function.py ../config_file.toml ../.env

# Push code package to S3
aws s3 cp lambda_code.zip s3://${input_s3_bucket}/scripts/lambda_code.zip

# Create lambda function
aws lambda create-function \
 --function-name ${function_name} \
 --region ${region} \
 --code S3Bucket=${input_s3_bucket},S3Key="scripts/lambda_code.zip" \
 --handler lambda_function.lambda_handler \
 --runtime python3.7 \
 --role arn:aws:iam::${account_id}:role/${lambda_role_name} \
 --layers arn:aws:lambda:${region}:${account_id}:layer:${lambda_layer_name}:${lambda_layer_version} \
 --timeout 30

# Removing the zip file to keep the folder clean
rm lambda_code.zip