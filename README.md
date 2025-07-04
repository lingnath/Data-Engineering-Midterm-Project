# Intro

I have created a fully automated data pipeline that ETLs data from source to destination, including a superset dashboard that analyzes the data warehouse

This project consists of 2 sections:
1. Setup
2. Run ETL

Below image outlines how to use the files I've provided so that you could use it to create an end-to-end data pipeline
<br>
![image](https://github.com/user-attachments/assets/00b390dd-051c-4879-90b9-653f8521b773)

## Setup

### 1. AWS setup
  - Create AWS account
  - Create IAM user with following policies attached
    ```
    - AmazonS3FullAccess
    - AmazonEC2FullAccess
    - AWSLambda_FullAccess
    - IAMFullAccess
    - AmazonAthenaFullAccess
    - AmazonElasticMapReduceFullAccess
    - AWSGlueConsoleFullAccess
    - AmazonEventBridgeFullAccess
    - AmazonSESFullAccess
    ```
  - Create an access key for this IAM user
### 2. EC2 Setup
  - Create and/or use an EC2 t2.xlarge instance running on Ubuntu 24.04
  - At least 24GB of EBS storage.
  - Ensure you create or use an existing key pair for login when setting up the EC2 instance
  - Under security group inbound rules, create or modify a security group with the following:
    - SSH Type (Port 22) from Source as MY IP
    - Port 8080 from Sources as Anywhere-IPv4 and Anywhere IPv6
    - Port 8088 from Sources as Anywhere-IPv4 and Anywhere IPv6
  - Attach this security group to your EC2 instance
  - Attach an elastic IP address to your EC2 instance. This is so that when accessing the Airflow DAG API, you can keep using the same url to do so
  - Upload the files in this repository into your EC2 folder
  - Make sure the role/instance profile has ```AmazonSSMManagedInstanceCore``` policy, with trust relationships being the following:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
 ```
### 3. Install Packages in EC2 Ubuntu
  - Run ```chmod +x <script>``` for each of the .sh scripts in the Software_Installations folder
  - Run the scripts within the Software_Installations folder in this order: ```./install_packages.sh``` -> ```./install_docker.sh``` -> ```./install_docker_compose.sh```
  - If you haven't done so already, run "aws configure" in the command line so that you can run the scripts on the EC2 command line without there being permission errors. Enter the following:
    ```
    - AWS Access Key ID [None]: {access key}
    - AWS Secret Access Key [None]: {secret access key}
    - Default region name [None]: {aws region your EC2 is in}
    - Default output format [None]: json
    ```
### 4. Set up config files
  - Create a ```.env``` file both in the main folder and the Airflow_EMR subfolder.
      - For the ```.env``` file in the main folder, the structure looks like this:
        ```
        - ACCESS_KEY=''
        - SECRET_KEY=''
        - ec2_instance_id=''
        ```
      - **NOTE**: If you feel the Airflow username and password are insecure, after Airflow is set up and the Lambda Function is created, please feel free to change the Airflow username and password for the above .env file in **both the AWS CLI and Lambda Function, as well as the username and password in the Airflow UI**. **But please make sure the changes you've made in all places are identical** as the Lambda function will not be able to call the Airflow DAG if the changes aren't the same.
      - For the .env file in the Airflow_EMR subfolder, the structure looks like this:
        ```
        - AIRFLOW__WEBSERVER__SECRET_KEY=
        - AIRFLOW__CORE__FERNET_KEY=
        - AIRFLOW_UID=1000
        - AIRFLOW_GID=0
        ```
      - To generate the ```AIRFLOW__WEBSERVER__SECRET_KEY``` and ```AIRFLOW__CORE__FERNET_KEY```, run ```python3 create_airflow_keys.py``` and then paste the print outputs to the ```.env``` file in the ```Airflow_EMR``` subfolder
    - Edit the fields in the ```config_file.toml``` file in the main folder
### 5. Create AWS artifacts
  - In the ```Create_AWS_Artifacts``` folder, run the following command ```chmod +x create_aws_artifacts.sh```. Then run ```./create_aws_artifacts.sh```
  - To ensure that your Lambda function can use SES, please check your email for the email address that you put in under sender field in the config_file.toml file and verify it for the confirmation email that AWS sent. The confirmation email should from no-reply-aws@amazon.com with the following subject line "Amazon Web Services – Email Address Verification Request in region {region you specified under the toml file}"
### 6. Setup and Run Airflow
  - Please go into the Airflow_EMR folder, run ```chmod +x build_airflow_in_docker.sh``` then run ```./build_airflow_in_docker.sh```
  - Create a port forwarding connection for port 8080 (optional if you want to access locally)
  - In your browser url, enter ```{EC2 Public IPv4 address}:8080```. This will lead you to the Airflow UI
  - In the Airflow_EMR folder, run ```chmod +x trigger_airflow.sh```
  - Then run ```./trigger_airflow.sh```
### 7. Setup and Run Superset
  - Go into the Superset folder, run ```chmod +x build_superset_in_docker.sh``` then run ```./build_superset_in_docker.sh```
  - Create a port forwarding connection for port 8088
  - Paste in [http://localhost:8088/login/](http://localhost:8088/login/) to login
  - Create a new database by entering the following to connect Superset to Athena:
```awsathena+rest://{aws access key}:{aws secret access key}@athena.{aws region}.amazonaws.com/?s3_staging_dir=s3://{output s3 bucket}/superset_metadata&work_group=primary```
  - Add the necessary datasets in Superset
  - Build dashboards to your heart's content
### 8. Remove AWS Artifacts (Optional)
  - Once you are done with the entire project, go into the ```Remove_AWS_Artifacts folder```.
  - Then run ```chmod +x remove_aws_artifacts.sh``` and then run ```./remove_aws_artifacts.sh```
### 9. EDA (Optional)
If you want to analyze the raw data before the ETL step, below steps will instruct you on how to do so <br>
  - Download the ```Local_EDA``` folder to your **local directory**. This part is meant to be done on your local machine so that you don't have to pay for an EC2 instance to run it
  - Make sure you have WSL or Ubuntu installed on your local machine
  - Go to ```Local_EDA``` folder. Once you are in ```Local_EDA``` folder, run the following:
```bash
chmod +x setup.sh
./setup.sh
```
  - Click on the Jupyter Notebook link provided in the terminal
  - Once you go to ```Spark_EDA.ipynb```, you can start analyzing the data by running each cell

## Run ETL
There are 2 options. 
1. We can run it manually by invoking the Lambda function we created by running ```start_ec2_instance.py``` either on the EC2 instance or even locally in your ```/home/ubuntu``` directory as long as you have the ```.env```, ```config_file.toml``` files, and you've run:
```bash
pip install boto3
pip install python_dotenv
pip install toml
```
on your Linux environment
2. Or we can wait until the cron schedule happens which will automatically run the ETL job.
