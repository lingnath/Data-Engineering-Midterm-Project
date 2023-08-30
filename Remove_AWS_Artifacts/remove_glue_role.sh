#!/bin/bash

glue_role_name=$(cat ../config_file.toml | grep 'glue_role_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Detach glue service role policy (we must detach policies first before we can delete the IAM role)
aws iam detach-role-policy \
 --role-name ${glue_role_name} \
 --policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole

# Detach S3 full access
aws iam detach-role-policy \
 --role-name ${glue_role_name} \
 --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Delete IAM role 
aws iam delete-role \
 --role-name ${glue_role_name}
