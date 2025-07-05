import os
import boto3
from dotenv import load_dotenv
from botocore import UNSIGNED
from botocore.config import Config
import toml
import time

# Loading the config toml file and .env file so that we can gather the variables from the respective files
load_dotenv('.env')
app_config = toml.load('config_file.toml')
s3_bucket_input_and_script = app_config['aws']['s3_bucket_input_and_script']
s3_bucket_output = app_config['aws']['s3_bucket_output']
aws_region = app_config['aws']['region']
tables = ['calendar', 'fact', 'product', 'store']
ACCESS_KEY = os.getenv('ACCESS_KEY')
SECRET_KEY = os.getenv('SECRET_KEY')

# Creating boto3 session for S3
session = boto3.Session(
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY
)

s3 = session.resource('s3')
s3_client = session.client('s3')

# Create an anonymous S3 client (no credentials) that we can download the public csv files with
s3_client_anon = boto3.client('s3', config=Config(signature_version=UNSIGNED))

# Get csv files from public bucket I shared
s3_bucket_public = 'wcd-de-midterm-nl-public'
local_download_dir = 'raw_csv_files'
os.makedirs(local_download_dir, exist_ok=True)
response_anon = s3_client_anon.list_objects_v2(Bucket=s3_bucket_public)
for obj in response_anon.get('Contents', []):
    key = obj['Key']
    local_file_path = os.path.join(local_download_dir, os.path.basename(key))
    
    # Download the csv file from public bucket
    s3_client_anon.download_file(s3_bucket_public, key, local_file_path)
    print(f"Downloaded: {key} -> {local_file_path}")

    # Upload csv file to s3
    renamed_csv_file = local_file_path.split("/")[-1].replace('mid', time.strftime("%Y-%m-%d"))
    s3_client.upload_file(local_file_path, s3_bucket_input_and_script, f'data/{renamed_csv_file}')
