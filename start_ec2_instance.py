import boto3
import os
import json
import toml
from dotenv import load_dotenv

# Get AWS credentials
load_dotenv("/home/ubuntu/.env")
app_config = toml.load('/home/ubuntu/config_file.toml')
access_key = os.getenv("ACCESS_KEY")
secret_access_key = os.getenv("SECRET_KEY")
aws_region = app_config['aws']['region']
lambda_function_name = app_config['aws']['lambda_function_name']

# Create Lambda client
lambda_client = boto3.client("lambda", 
                                region_name=aws_region,
                                aws_access_key_id=access_key, 
                                aws_secret_access_key=secret_access_key
                                )

# Send payload to AWS Lambda function to stop EC2 instance
payload = {'action': 'start'}
response = lambda_client.invoke(
    FunctionName=lambda_function_name,
    InvocationType='RequestResponse',
    Payload=json.dumps(payload),
)
