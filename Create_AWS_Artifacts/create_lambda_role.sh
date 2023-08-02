#!/bin/bash

lambda_role_name=$(cat ../config_file.toml | grep 'lambda_role_name' | awk -F"=" '{print $2}' | tr -d "'")

# Create IAM role 
aws iam create-role \
 --role-name ${lambda_role_name} \
 --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'

# Attach lambda basic execution policy
aws iam attach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Attach S3 full access so that Lambda can read the buckets
aws iam attach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Attach SES full access, so that the email script in Lambda will work
aws iam attach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/AmazonSESFullAccess