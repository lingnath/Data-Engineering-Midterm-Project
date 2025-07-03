import json
import boto3
import time
import os
import subprocess
from botocore.exceptions import ClientError
import toml
from dotenv import load_dotenv

def send_email(sender, recipient, aws_region):
    # The subject line for the email.
    SUBJECT = "Files missing in S3 bucket"

    # The email body for recipients with non-HTML email clients.
    BODY_TEXT = ("Files missing in AWS S3 bucket. Please check load to S3 task.")

    # The character encoding for the email.
    CHARSET = "UTF-8"

    # Create a new SES resource and specify a region.
    client = boto3.client('ses', region_name=aws_region)

    # Try to send the email.
    try:
        #Provide the contents of the email.
        response = client.send_email(
            Destination={
                'ToAddresses': [
                    recipient,
                ],
            },
            Message={
                'Body': {
                    'Text': {
                        'Charset': CHARSET,
                        'Data': BODY_TEXT,
                    },
                },
                'Subject': {
                    'Charset': CHARSET,
                    'Data': SUBJECT,
                },
            },
            Source=sender

        )
    # Display an error if something goes wrong. 
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        print("Email sent! Message ID:"),
        print(response['MessageId'])


def lambda_handler(event, context):
    
    # Load variables from the .env and config toml files
    load_dotenv()
    app_config = toml.load('config_file.toml')
    aws_region = app_config['aws']['region']
    s3_bucket = app_config['aws']['s3_bucket_input_and_script']
    ec2_ip_address = app_config['aws']['ec2_ip_address']
    sender = app_config['email']['sender']
    recipient = app_config['email']['recipient']
    dag_name = app_config['airflow']['dag_name']

    s3_file_list_raw = []

    # Get all the keys within the data folder of the input S3 bucket
    s3_client=boto3.client('s3')
    for object in s3_client.list_objects_v2(Bucket=s3_bucket, Prefix='data/')['Contents']:
        s3_file_list_raw.append(object['Key'])

    # Getting the file names for all the csv files within the data folder of the input S3 bucket. 
    # Note that we will ignore the data folder object itself as it's not a csv file
    s3_file_list = [obj.split('/')[-1] for obj in s3_file_list_raw if obj!='data/']
    print('s3_file_list: ', s3_file_list)
    
    # Getting the required files list, which consist of all the tables pushed today from to S3
    datestr = time.strftime("%Y-%m-%d")
    required_file_list = [f'calendar_{datestr}.csv', f'inventory_{datestr}.csv', f'product_{datestr}.csv', f'sales_{datestr}.csv', f'store_{datestr}.csv']
    print('required_file_list: ', required_file_list)
    
    # Only activate Airflow if the input bucket has all the required files
    if set(required_file_list).issubset(s3_file_list):
        required_file_url = ['s3://' + f'{s3_bucket}/data/' + a for a in required_file_list]
        print('required_file_url: ', required_file_url)
        table_name = [a[:-15] for a in required_file_list]
        print('table_name: ', table_name)
        data = json.dumps({'conf':{a:b for a,b in zip(table_name, required_file_url)}})
        print(data)
    # send signal to Airflow    
        endpoint = f'http://{ec2_ip_address}:8080/api/v1/dags/{dag_name}/dagRuns'
        user_credentials = f'{os.getenv("AIRFLOW_USERNAME")}:{os.getenv("AIRFLOW_PASSWORD")}'
        subprocess.run([
            'curl', 
            '-X',
            'POST',
            endpoint,
            '-H',
            'accept: application/json',
            '-H',
            'Content-Type: application/json',
            '--user',
            user_credentials,
            '--data',
            data])
        print('File are send to Airflow')
    else:
        # If required files aren't found in the input bucket, send email to user reminding them of such
        send_email(sender, recipient, aws_region)
