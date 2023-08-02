import os
import boto3
from dotenv import load_dotenv
import toml

# Loading the config toml file and .env file so that we can gather the variables from the respective files
load_dotenv('../.env')
app_config = toml.load('../config_file.toml')
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

# Create input bucket
s3_client.create_bucket(
    Bucket=s3_bucket_input_and_script,  
    CreateBucketConfiguration={'LocationConstraint': aws_region} 
)

# Create a data folder for the input bucket where the raw tables (from Snowflake) can reside
s3_client.put_object(
    Bucket=s3_bucket_input_and_script,
    Key=('data/'))

# Upload pyspark script to input bucket
s3_client.upload_file('Spark_ETL.py', s3_bucket_input_and_script, 'scripts/Spark_ETL.py')

# Create output bucket
s3_client.create_bucket(
    Bucket=s3_bucket_output,  
    CreateBucketConfiguration={'LocationConstraint': aws_region} 
)

# Creating a folder for the output bucket where the transformed tables can reside
for table in tables:
    s3_client.put_object(
        Bucket=s3_bucket_output,
        Key=(f'data/{table}/'))

# Creating a folder for the output bucket where Superset metadata can be populated
s3_client.put_object(
    Bucket=s3_bucket_output,
    Key=('superset_metadata/'))

# Creating a folder for the output bucket where Athena query results can reside
s3_client.put_object(
    Bucket=s3_bucket_output,
    Key=('athena_metadata/'))