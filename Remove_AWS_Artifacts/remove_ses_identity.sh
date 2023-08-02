#!/bin/bash

email_address=$(cat ../config_file.toml | grep 'sender' | awk -F"=" '{print $2}' | tr -d "'")
aws_region=$(cat ../config_file.toml | grep 'region' | awk -F"=" '{print $2}' | tr -d "'")

# Removes your email from SES
aws sesv2 delete-email-identity \
 --email-identity ${email_address} \
 --region ${aws_region}