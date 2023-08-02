import os
import boto3
from dotenv import load_dotenv
import toml

# Loading config toml file and .env file to gather the variables from the respective files
load_dotenv('../.env')
app_config = toml.load('../config_file.toml')
s3_bucket_input_and_script = app_config['aws']['s3_bucket_input_and_script']
s3_bucket_output = app_config['aws']['s3_bucket_output']

ACCESS_KEY = os.getenv('ACCESS_KEY')
SECRET_KEY = os.getenv('SECRET_KEY')

# Creating boto3 session for S3
session = boto3.Session(
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY
)

s3 = session.resource('s3')
s3_client = session.client('s3')

bucket_names = [s3_bucket_input_and_script, s3_bucket_output]

# Removing input and output S3 buckets, including all the files and folders within
for bucket_name in bucket_names:
    bucket = s3.Bucket(bucket_name)
    bucket_versioning = s3.BucketVersioning(bucket_name)
    if bucket_versioning.status == 'Enabled':
        bucket.object_versions.delete()
    else:
        bucket.objects.all().delete()
    response = bucket.delete()