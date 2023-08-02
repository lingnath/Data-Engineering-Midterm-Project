#!/bin/bash
function_name=$(cat ../config_file.toml | grep 'lambda_function_name' | awk -F"=" '{print $2}' | tr -d "'")
region=$(cat ../config_file.toml | grep 'region' | awk -F"=" '{print $2}' | tr -d "'")

# Below script invokes the lambda function so that we don't have to use the AWS management console to trigger the lambda function
cd ..
aws lambda invoke --function-name ${function_name} \
 --region ${region} \
 --payload '{"key1": "value1","key2": "value2","key3": "value3"}' logs/lambda_output.txt