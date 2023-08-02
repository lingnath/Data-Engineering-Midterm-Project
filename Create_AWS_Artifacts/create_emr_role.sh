#!/bin/bash

aws emr create-default-roles 

# Invoke the sleep function so that AWS can take a bit of time to recognize the newly created roles
# before attaching policies to it
sleep 3

 # Attach S3 full access policy so that EMR can read and update from the input and output S3 buckets respectively
aws iam attach-role-policy \
 --role-name EMR_EC2_DefaultRole \
 --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess