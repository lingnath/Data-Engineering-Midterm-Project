#!/bin/bash

lambda_role_name=$(cat ../config_file.toml | grep 'lambda_role_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Create IAM role 
aws iam create-role \
 --role-name ${lambda_role_name} \
 --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'

# Attach lambda basic execution policy
aws iam attach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Attach EC2 full access so that Lambda can start EC2
aws iam attach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# Attach SSM full access, so that Lambda can pass scripts into the EC2 instance
aws iam attach-role-policy \
 --role-name ${lambda_role_name} \
 --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
