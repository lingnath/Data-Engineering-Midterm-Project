# Intro

I have created a fully automated data pipeline that ETLs retail data from source to destination, including a superset dashboard that analyzes the data warehouse.

This project consists of 2 sections:
1. Setup
2. Run ETL

Below image outlines how to use the files I've provided so that you could use it to create an end-to-end data pipeline
<br>
![image](https://github.com/user-attachments/assets/00b390dd-051c-4879-90b9-653f8521b773)

### Limitations
1. The source data, which generated new data every day, is no longer available. Therefore, I had to save the static raw data and host it in my own S3 public bucket, which you can load it by running the ```python3 upload_raw_files.py``` script. Therefore, this is no longer a traditional ETL process because there is no daily data. For the sake of this project, we are still able to create a fully automated ETL pipeline, even if the data is static.
2. In a production setting, I will have tightened the IAM restrictions significant to protect the data and pipeline. However, given that this is meant to be a personal project and the source data is made up with no personally identifiable information, the relatively lax IAM policies should not be an issue.

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
    - Port 8080 from Sources as MY IP
    - Port 8088 from Sources as MY IP
  - Attach this security group to your EC2 instance
  - In ```/home/ubuntu/``` folder, run ```git clone https://github.com/lingnath/Data-Engineering-Midterm-Project.git```
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
  - Run ```chmod +x <script>``` for each of the .sh scripts in the ```Software_Installations``` folder
  - Run the scripts within the ```Software_Installations``` folder in this order: ```./install_packages.sh``` -> ```./install_docker.sh``` -> ```./install_docker_compose.sh```
  - If you haven't done so already, run "aws configure" in the command line so that you can run the scripts on the EC2 command line without there being permission errors. Enter the following:
    ```
    - AWS Access Key ID [None]: {access key}
    - AWS Secret Access Key [None]: {secret access key}
    - Default region name [None]: {aws region your EC2 is in}
    - Default output format [None]: json
    ```
### 4. Set up config files
  - Create a ```.env``` file both in the main folder and the ```Airflow_EMR``` folder.
  - For the ```.env``` file in the main folder, the structure looks like this:
    ```
    - ACCESS_KEY=''
    - SECRET_KEY=''
    - ec2_instance_id=''
    ```
  - **NOTE**: If you feel the Airflow username and password are insecure, after Airflow is set up and the Lambda Function is created, please feel free to change the Airflow username and password for the above .env file in **both the AWS CLI and Lambda Function, as well as the username and password in the Airflow UI**. **But please make sure the changes you've made in all places are identical** as the Lambda function will not be able to call the Airflow DAG if the changes aren't the same.
  - For the .env file in the ```Airflow_EMR``` folder, the structure looks like this:
    ```
    - AIRFLOW__WEBSERVER__SECRET_KEY=
    - AIRFLOW__CORE__FERNET_KEY=
    - AIRFLOW_UID=1000
    - AIRFLOW_GID=0
    ```
  - To generate the ```AIRFLOW__WEBSERVER__SECRET_KEY``` and ```AIRFLOW__CORE__FERNET_KEY```, run
  - ```bash
    source /home/ubuntu/Data-Engineering-Midterm-Project/Software_Installations/python_env/bin/activate
    python3 /home/ubuntu/Data-Engineering-Midterm-Project/Airflow_EMR/create_airflow_keys.py
    ```
  - Then paste the print outputs to the ```.env``` file in the ```Airflow_EMR``` folder
  - Edit the fields in the ```config_file.toml``` file in the main folder
### 5. Create AWS artifacts
  - In the ```Create_AWS_Artifacts``` folder,
  - Run the following commands
  - ```bash
    chmod +x create_aws_artifacts.sh
    source /home/ubuntu/Data-Engineering-Midterm-Project/Software_Installations/python_env/bin/activate
    ```
  - Then run ```./create_aws_artifacts.sh```
  - To ensure that your Lambda function can use SES, please check your email for the email address that you put in under sender field in the config_file.toml file and verify it for the confirmation email that AWS sent. The confirmation email should from no-reply-aws@amazon.com with the following subject line "Amazon Web Services – Email Address Verification Request in region {region you specified under the toml file}"
### 6. Setup and Run Airflow
  - Please go into the ```Airflow_EMR``` folder, run ```chmod +x build_airflow_in_docker.sh``` then run ```./build_airflow_in_docker.sh```
  - Create a port forwarding connection for port 8080 (optional if you want to access locally)
  - In your browser url, enter ```{EC2 Public IPv4 address}:8080```. This will lead you to the Airflow UI
  - Go to your DAG in the Airflow UI and run ```Trigger DAG```
### 7. Setup and Run Superset
  - Go into the ```Superset``` folder, run ```chmod +x build_superset_in_docker.sh``` then run ```./build_superset_in_docker.sh```
  - Create a port forwarding connection for port 8088
  - Paste in [http://localhost:8088/login/](http://localhost:8088/login/) to login
  - Create a new database by entering the following to connect Superset to Athena:
```awsathena+rest://{aws access key}:{aws secret access key}@athena.{aws region}.amazonaws.com/?s3_staging_dir=s3://{output s3 bucket}/superset_metadata&work_group=primary```
  - Add the necessary datasets in Superset
  - Build dashboards to your heart's content
### 8. Remove AWS Artifacts (Optional)
  - Once you are done with the entire project, go into the ```Remove_AWS_Artifacts``` folder.
  - Run the following commands
  - ```bash
    chmod +x remove_aws_artifacts.sh
    source /home/ubuntu/Data-Engineering-Midterm-Project/Software_Installations/python_env/bin/activate
    ```
  - Then run ```./remove_aws_artifacts.sh```
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

### Important Consideration
This is not a traditional ETL process because the data is static and DOES NOT get uploaded to the input S3 bucket on a scheduled basis. If we run the ETL script on a day that does not match the date of the csv file, we will not retrieve anything. ```upload_raw_files.py``` will upload the csv files from my public S3 bucket to the input S3 bucket we've created named **today's date**. Therefore, if you want to run the ETL job and the csv files are from a date in the past that is not today, please run ```python3 upload_raw_files.py``` before running the ETL Job.

### Running ETL Job
There are 3 options. 
1. We can run ```start_ec2_instance.py``` manually in the EC2 on ```/home/ubuntu/Data-Engineering-Midterm-Project/``` directory where you will need to run the following:
```bash
source /home/ubuntu/Data-Engineering-Midterm-Project/Software_Installations/python_env/bin/activate
python3 start_ec2_instance.py
```
2. Run ```start_ec2_instance.py``` locally on ```/home/ubuntu/Data-Engineering-Midterm-Project/``` directory as long as you have the ```.env```, ```config_file.toml``` files in the same directory, and on your Linux CLI, you will need to run the following:
```bash
sudo apt-get install python3.12 -y
sudo apt install python3.12-venv
python3 -m venv python_env
source python_env/bin/activate
pip install boto3
pip install python_dotenv
pip install toml
python3 start_ec2_instance.py
```
3. Or we can wait until the cron schedule happens which will automatically run the ETL job.
