#!/bin/bash
input_s3_bucket=$(cat ../config_file.toml | grep 's3_bucket_input_and_script' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
lambda_layer_name=$(cat ../config_file.toml | grep 'lambda_layer_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
region=$(cat ../config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
dir="lambda_layer"

# Create the directory for the Lambda Layer
if [ ! -d $dir ]; then
    mkdir $dir
fi
mkdir -p ${dir}/python/lib/python3.12/site-packages

# Installing the libraries and packaging into zip file
pip3 install -r requirements.txt --target ${dir}/python/lib/python3.12/site-packages
cd $dir
zip -r9 lambda_libraries.zip .

# Pushing the zip file to S3
aws s3 cp lambda_libraries.zip s3://${input_s3_bucket}/scripts/lambda_libraries.zip

# Creating the lambda layer and attaching the zip file to it
aws lambda publish-layer-version \
    --layer-name ${lambda_layer_name} \
    --region ${region} \
    --content S3Bucket=${input_s3_bucket},S3Key="scripts/lambda_libraries.zip" \
    --compatible-runtimes python3.12 \
    --compatible-architectures x86_64

# Removing the files and folders to keep the folder clean
cd .. && rm -r $dir
