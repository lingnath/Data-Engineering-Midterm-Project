#!/bin/bash

lambda_layer_name=$(cat ../config_file.toml | grep 'lambda_layer_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
region=$(cat ../config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
lambda_layer_version=$(cat ../config_file.toml | grep 'lambda_layer_version' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Removes the lambda layer
aws lambda delete-layer-version \
    --layer-name ${lambda_layer_name} \
    --version-number ${lambda_layer_version} \
    --region ${region}
