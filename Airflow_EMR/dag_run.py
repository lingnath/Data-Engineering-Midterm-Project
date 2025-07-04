import airflow
from airflow import DAG
from datetime import timedelta
from airflow.operators.python_operator import PythonOperator, BranchPythonOperator
from airflow.providers.amazon.aws.operators.emr import EmrAddStepsOperator, EmrCreateJobFlowOperator, EmrTerminateJobFlowOperator
from airflow.providers.amazon.aws.sensors.emr import EmrStepSensor
from airflow.providers.amazon.aws.operators.glue_crawler import GlueCrawlerOperator
from airflow.operators.dummy import DummyOperator
import toml
from dotenv import load_dotenv
import os
import boto3
from botocore.exceptions import ClientError
import json
import time

load_dotenv()
access_key = os.getenv("ACCESS_KEY")
secret_access_key = os.getenv("SECRET_KEY")

# Loading the variables from config toml file
app_config = toml.load('/opt/airflow/config_file.toml')
s3_input_bucket = app_config['aws']['s3_bucket_input_and_script']
s3_output_bucket = app_config['aws']['s3_bucket_output']
glue_role_name = app_config['aws']['glue_role_name']
glue_crawler_name = app_config['aws']['glue_crawler_name']
athena_db = app_config['aws']['athena_db']
dag_name = app_config['airflow']['dag_name']
sender = app_config['email']['sender']
recipient = app_config['email']['recipient']
aws_region = app_config['aws']['region']


# Creating the Spark Steps configurations to pass to the EMR cluster
SPARK_STEPS = [
    {
        'Name': 'wcd_data_engineer',
        'ActionOnFailure': "CONTINUE",
        'HadoopJarStep': {
            'Jar': 'command-runner.jar',
            'Args': [
                '/usr/bin/spark-submit',
                '--master', 'yarn',
                '--deploy-mode', 'client', # Client mode enabled for debugging purposes in EMR
                f's3://{s3_input_bucket}/scripts/Spark_ETL.py',
                '--spark_name', 'mid-term',
                '--data', "{{ task_instance.xcom_pull('parse_request', key='data') }}",
                '--output_path', f's3://{s3_output_bucket}/data/'
            ]
        }
    }

]

# Setting up the default arguments for the dag
DEFAULT_ARGS = {
    'owner': 'wcd_data_engineer',
    'depends_on_past': False,
    'start_date': airflow.utils.dates.days_ago(0),
    'email': ['airflow_data_eng@wcd.com'],
    'email_on_failure': False,
    'email_on_retry': False
}

# Creating the configurations for the glue crawlers (a separate crawler exists for the calendar, 
# product, store, and fact tables)
cal_config = {
    "Name": f"{glue_crawler_name}_calendar",
    "Role": glue_role_name,
    "DatabaseName": athena_db,
    'Targets': {'S3Targets': [{'Path': f"s3://{s3_output_bucket}/data/calendar/" }]}
}

fact_config = {
    "Name": f"{glue_crawler_name}_fact",
    "Role": glue_role_name,
    "DatabaseName": athena_db,
    'Targets': {'S3Targets': [{'Path': f"s3://{s3_output_bucket}/data/fact/" }]}
}

product_config = {
    "Name": f"{glue_crawler_name}_product",
    "Role": glue_role_name,
    "DatabaseName": athena_db,
    'Targets': {'S3Targets': [{'Path': f"s3://{s3_output_bucket}/data/product/" }]}
}

store_config = {
    "Name": f"{glue_crawler_name}_store",
    "Role": glue_role_name,
    "DatabaseName": athena_db,
    'Targets': {'S3Targets': [{'Path': f"s3://{s3_output_bucket}/data/store/" }]}
}

# Creating the parameters to the EMR that will be created. This is a section to customize your EMR cluster
JOB_FLOW_OVERRIDES = {
    "Name": "wcd_data_engineer",
    "ReleaseLabel": "emr-6.10.0",
    "Applications": [{"Name": "Spark"}],
    "Instances": {
        "InstanceGroups": [
            {
                "Name": "Master node",
                "Market": "ON_DEMAND",
                "InstanceRole": "MASTER",
                "InstanceType": "m4.xlarge", # m4.xlarge was chosen because there were frequent out of capacity issues for m5.xlarge
                "InstanceCount": 1,
            },
            {    
                    'Name': "Slave nodes",    
                    'Market': 'ON_DEMAND',
                    'InstanceRole': 'CORE',    
                    'InstanceType': 'm4.xlarge',    
                    'InstanceCount': 2    
            }    
        ],
        "KeepJobFlowAliveWhenNoSteps": True,
        "TerminationProtected": False,
    },
    "JobFlowRole": "EMR_EC2_DefaultRole",
    "ServiceRole": "EMR_DefaultRole",
}

def send_email(sender, recipient, aws_region):
    # The subject line for the email.
    SUBJECT = "Files missing in S3 bucket"

    # The email body for recipients with non-HTML email clients.
    BODY_TEXT = ("Files missing in AWS S3 bucket. Please check load to S3 task.")

    # The character encoding for the email.
    CHARSET = "UTF-8"

    # Create a new SES resource and specify a region.
    client = boto3.client('ses', 
                            region_name=aws_region,
                            aws_access_key_id=access_key, 
                            aws_secret_access_key=secret_access_key)

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

# Creating a function that passes the data from Lambda's API call to Airflow's tasks
def retrieve_s3_files(**kwargs):

    s3_file_list_raw = []

    # Get all the keys within the data folder of the input S3 bucket
    s3_client=boto3.client('s3',
                            aws_access_key_id=access_key, 
                            aws_secret_access_key=secret_access_key)
    for object in s3_client.list_objects_v2(Bucket=s3_input_bucket, Prefix='data/')['Contents']:
        s3_file_list_raw.append(object['Key'])

    # Getting the file names for all the csv files within the data folder of the input S3 bucket. 
    # Note that we will ignore the data folder object itself as it's not a csv file
    s3_file_list = [obj.split('/')[-1] for obj in s3_file_list_raw if obj!='data/']
    print('s3_file_list: ', s3_file_list)
    
    # Getting the required files list, which consist of all the tables pushed today from to S3
    datestr = time.strftime("%Y-%m-%d")
    required_file_list = [f'calendar_{datestr}.csv', f'inventory_{datestr}.csv', f'product_{datestr}.csv', f'sales_{datestr}.csv', f'store_{datestr}.csv']
    print('required_file_list: ', required_file_list)
    
    # Only activate EMR and Glue if the input bucket has all the required files
    if set(required_file_list).issubset(s3_file_list):
        required_file_url = ['s3://' + f'{s3_input_bucket}/data/' + a for a in required_file_list]
        print('required_file_url: ', required_file_url)
        table_name = [a[:-15] for a in required_file_list]
        print('table_name: ', table_name)
        data = {a:b for a,b in zip(table_name, required_file_url)}
        print(data)
        kwargs['ti'].xcom_push(key='data', value=data)
        return "create_emr_cluster"
    # Otherwise we stop the process abruptly and send an email notifying of missing files
    else:
        send_email(sender, recipient, aws_region)
        return "end"

# Initializing the dag
dag = DAG(
    dag_name,
    default_args=DEFAULT_ARGS,
    dagrun_timeout=timedelta(hours=2),
    schedule_interval=None
)

begin = DummyOperator(task_id="begin",
        dag=dag
    )

# Creating a PythonOperator that utilizes the python function created above.
# Retrieves the S3 URIs for each of the raw input tables
parse_request = BranchPythonOperator(task_id='parse_request',
                                provide_context=True, # Airflow will pass a set of keyword arguments that can be used in your function
                                python_callable=retrieve_s3_files,
                                dag=dag
                                ) 

# Creating the EMR cluster
create_emr_cluster = EmrCreateJobFlowOperator(
    task_id="create_emr_cluster",
    job_flow_overrides=JOB_FLOW_OVERRIDES,
    aws_conn_id="aws_conn",
    dag=dag
    )

# Adding steps to the EMR cluster
step_adder = EmrAddStepsOperator(
    task_id='add_steps',
    job_flow_id="{{ task_instance.xcom_pull('create_emr_cluster', key='return_value') }}",
    aws_conn_id="aws_conn",
    steps=SPARK_STEPS,
    dag=dag
)

# Monitoring the steps of the EMR cluster
step_checker = EmrStepSensor(
    task_id='watch_step',
    job_flow_id="{{ task_instance.xcom_pull('create_emr_cluster', key='return_value') }}",
    step_id="{{ task_instance.xcom_pull('add_steps', key='return_value')[0] }}",
    aws_conn_id="aws_conn", 
    dag=dag
)

# Removing the EMR cluster once the EMR job is completed
remove_emr_cluster = EmrTerminateJobFlowOperator(
        task_id='remove_emr_cluster',
        job_flow_id="{{ task_instance.xcom_pull('create_emr_cluster', key='return_value') }}",
        aws_conn_id='aws_conn',
        trigger_rule='all_done',
        dag=dag
    )

# Triggering the Glue Crawler to create schemas for the calendar, product, store and fact tables
run_glue_crawler_calendar = GlueCrawlerOperator(
        task_id="run_glue_crawler_calendar",
        aws_conn_id="aws_conn",
        config=cal_config, 
        dag=dag      
    )
run_glue_crawler_fact = GlueCrawlerOperator(
        task_id="run_glue_crawler_fact",
        aws_conn_id="aws_conn",
        config=fact_config, 
        dag=dag             
    )

run_glue_crawler_product = GlueCrawlerOperator(
        task_id="run_glue_crawler_product",
        aws_conn_id="aws_conn",
        config=product_config, 
        dag=dag             
    )

run_glue_crawler_store = GlueCrawlerOperator(
        task_id="run_glue_crawler_store",
        aws_conn_id="aws_conn",
        config=store_config, 
        dag=dag             
    )

end = DummyOperator(task_id="end",
        dag=dag
    )

# Connecting the steps together into a unified workflow

begin >> parse_request

parse_request >> create_emr_cluster >> step_adder >> step_checker >> remove_emr_cluster >> [run_glue_crawler_calendar, run_glue_crawler_fact, run_glue_crawler_product, run_glue_crawler_store] >> end
parse_request >> end
