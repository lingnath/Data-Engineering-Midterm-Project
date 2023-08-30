#!/bin/bash

access_key=$(cat .env | grep 'ACCESS_KEY' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
secret_access_key=$(cat .env | grep 'SECRET_KEY' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
region=$(cat config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
dag_name=$(cat config_file.toml | grep 'dag_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
extras='{"region_name":''"'"${region}"'"''}'

# Create the aws connection
airflow connections add "aws_conn" \
    --conn-type "aws" \
    --conn-login "$access_key" \
    --conn-password "$secret_access_key" \
    --conn-extra "${extras}"

# Unpause the dag (so that we can actually run it)
airflow dags unpause ${dag_name}
