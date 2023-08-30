#!/bin/bash

lambda_schedule_rule_name=$(cat ../config_file.toml | grep 'lambda_schedule_rule_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
aws_region=$(cat ../config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
account_id=$(cat ../config_file.toml | grep 'account_id' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
lambda_function_name=$(cat ../config_file.toml | grep 'lambda_function_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Remove lambda function permissions for the event rule trigger
aws lambda remove-permission \
 --function-name ${lambda_function_name} \
 --statement-id lambda-scheduled-trigger

sleep 3

# Detaches the event rule trigger from lambda function
target_id=$(aws events list-targets-by-rule --rule ${lambda_schedule_rule_name} | awk -F ':' 'FNR == 4 {print $2}' | awk -F '"' '{print $2}')
aws events remove-targets --rule ${lambda_schedule_rule_name} \
 --ids ${target_id}

sleep 3

# Remove the event rule trigger entirely
 aws events delete-rule \
 --name ${lambda_schedule_rule_name} \
 --region ${aws_region}
