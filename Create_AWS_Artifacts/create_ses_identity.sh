#!/bin/bash

email_address=$(cat ../config_file.toml | grep 'sender' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
aws_region=$(cat ../config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Configure email in SES
aws sesv2 create-email-identity \
 --email-identity ${email_address} \
 --region ${aws_region}
