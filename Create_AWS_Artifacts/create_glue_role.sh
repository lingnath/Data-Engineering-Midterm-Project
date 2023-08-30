#!/bin/bash

glue_role_name=$(cat ../config_file.toml | grep 'glue_role_name' | awk -F"=" '{print $2}' | tr -d "'" | tr -d " ")

# Create IAM role 
aws iam create-role \
 --role-name ${glue_role_name} \
 --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "glue.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'

# Attach glue service role
aws iam attach-role-policy \
 --role-name ${glue_role_name} \
 --policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole

# Attach S3 full access so that Glue can read the files in S3
aws iam attach-role-policy \
 --role-name ${glue_role_name} \
 --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
