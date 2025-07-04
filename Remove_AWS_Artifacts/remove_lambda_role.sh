#!/bin/bash

lambda_role_name=$(cat ../config_file.toml | grep 'lambda_role_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Detach lambda basic execution policy
aws iam detach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Detach EC2 full access
aws iam detach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# Detach SSM full access
aws iam detach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess

 # Delete IAM role
aws iam delete-role \
 --role-name ${lambda_role_name}
