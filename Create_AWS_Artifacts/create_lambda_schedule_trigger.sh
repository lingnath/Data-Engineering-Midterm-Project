#!/bin/bash

lambda_schedule_rule_name=$(cat ../config_file.toml | grep 'lambda_schedule_rule_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
aws_region=$(cat ../config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
account_id=$(cat ../config_file.toml | grep 'account_id' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
lambda_function_name=$(cat ../config_file.toml | grep 'lambda_function_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Define Lambda Payload
payload='{"action":"start"}'

# Create event rule trigger in Amazon Eventbridge so that Lambda could be invoked at a specific time interval
aws events put-rule \
 --name ${lambda_schedule_rule_name} \
 --region ${aws_region} \
 --schedule-expression "cron(0 9 * * ? *)" # Runs at 9am daily UTC, which is 5am EST, 1 hour after the scheduled push to the s3 bucket from Snowflake

# Sleep command applied to give a bit of time so that Lambda can detect the newly created Eventbridge rule
sleep 3

# Add permission so that Lambda is given the permission to attach the Eventbridge rule trigger
aws lambda add-permission \
--function-name ${lambda_function_name} \
--statement-id lambda-scheduled-trigger \
--action 'lambda:InvokeFunction' \
--principal events.amazonaws.com \
--source-arn arn:aws:events:${aws_region}:${account_id}:rule/${lambda_schedule_rule_name}

# Creating the json file for the next step below
touch targets.json
lambda_function_arn="arn:aws:lambda:${aws_region}:${account_id}:function:${lambda_function_name}"
echo "[" >> targets.json
echo -e "\t{" >> targets.json
echo '      "Id": "1",' >> targets.json
echo '      "Arn":"'${lambda_function_arn}'"' >> targets.json
# echo '    "Input": "'"${payload}"'"' >> targets.json
echo -e "\t}" >> targets.json
echo "]" >> targets.json

sleep 3

# Attaching the Eventbridge rule trigger to Lambda function
aws events put-targets \
 --rule ${lambda_schedule_rule_name} \
 --region ${aws_region} \
 --targets file://targets.json

# Remove the json file so that there aren't any conflicts the next time we rerun this script
rm targets.json
