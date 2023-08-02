#!/bin/bash

function_name=$(cat ../config_file.toml | grep 'lambda_function_name' | awk -F"=" '{print $2}' | tr -d "'")
region=$(cat ../config_file.toml | grep 'region' | awk -F"=" '{print $2}' | tr -d "'")

# Removes the lambda function
aws lambda delete-function \
 --function-name ${function_name} \
 --region ${region}