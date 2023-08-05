This page outlines how to use the files I've provided so that you could use it to create an end-to-end data pipeline
<br>
![image](https://github.com/lingnath/Data-Engineering-Midterm-Project/assets/32849838/55879ee9-38a8-41cf-ba7e-e701ba1fb754)

## 1. AWS setup
  - Create AWS account
  - Create IAM user with following policies attached
    - S3FullAccess
    - AmazonEC2FullAccess
    - AWSLambda_FullAccess
    - IAMFullAccess
    - AmazonAthenaFullAccess
    - AmazonElasticMapReduceFullAccess
    - AWSGlueConsoleFullAccess
    - AmazonEventBridgeFullAccess
    - AmazonSESFullAccess
  - Create an access key for this IAM user
## 2. Snowflake setup
  - Create Snowflake account
  - Copy and paste the SQL files into the worksheets section in your Snowflake UI
  - Configure Snowflake Storage Integration with AWS S3. <a href="https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration#step-2-create-the-iam-role-in-aws">This link</a> will provide the instructions
  - Change the fields in the snowflake SQL files to match the parameters you have set up.
    - **NOTE**: Please do not run the sql queries I've provided on Snowflake yet. We need to create the s3 bucket in the Create_AWS_Artifacts folder step first before we can load the Snowflake data to S3
## 3. EC2 Setup
  - Create and/or use an EC2 t2.xlarge instance running on Ubuntu, with >=24GB of EBS storage.
  - Ensure you create or use an existing key pair for login when setting up the EC2 instance
  - Under security group inbound rules, create or modify a security group with the following:
    - SSH Type (Port 22) from Source as MY IP
    - Port 8080 from Sources as Anywhere-IPv4 and Anywhere IPv6
    - Port 8088 from Sources as Anywhere-IPv4 and Anywhere IPv6
  - Attach this security group to your EC2 instance
  - Attach an elastic IP address to your EC2 instance. This is so that when accessing the Airflow DAG API, you can keep using the same url to do so
  - Upload the files in this repository into your EC2 folder
## 4. Install Packages in EC2 Ubuntu
  - Run "chmod +x <script>" for each of the .sh scripts in the Software_Installations folder
  - Run the scripts within the Software_Installations folder in this order: install_packages.sh >> install_docker.sh >> install_docker_compose.sh
  - If you haven't done so already, run "aws configure" in the command line. Then enter your credentials, such as your newly generated access key and secret access key for the user you created, so that you can run the scripts on the EC2 command line without there being permission errors.
## 5. Set up config files
  - Create a .env file both in the main folder and the Airflow_EMR subfolder.
      - For the .env file in the main folder, the structure looks like this:
        - ACCESS_KEY = ""
        - SECRET_KEY = ""
        - AIRFLOW_USERNAME = 'admin'
        - AIRFLOW_PASSWORD = 'admin'
      - **NOTE**: If you feel the Airflow username and password are insecure, after Airflow is set up and the Lambda Function is created, please feel free to change the Airflow username and password for the above .env file in **both the AWS CLI and Lambda Function, as well as the username and password in the Airflow UI**. **But please make sure the changes you've made in all places are identical** as the Lambda function will not be able to call the Airflow DAG if the changes aren't the same.
      - For the .env file in the Airflow_EMR subfolder, the structure looks like this:
        - AIRFLOW__WEBSERVER__SECRET_KEY=229e57aeb295d76f2db5d75bfa78865c7e40b17e6db96cae8d
        - AIRFLOW__CORE__FERNET_KEY=46BKJoQYlPPOexq0OhDZnIlNepKFf87WFwLbfzqDDho=
        - AIRFLOW_UID=1000
        - AIRFLOW_GID=0
    - Edit the fields in the config_file.toml file in the main folder
## 6. Create AWS artifacts
  - In the Create_AWS_Artifacts folder, run the following command "chmod +x create_aws_artifacts.sh". Then run create_aws_artifacts.sh
  - To ensure that your Lambda function can use SES, please check your email for the email address that you put in under sender field in the config_file.toml file and verify it for the confirmation email that AWS sent. The confirmation email should from no-reply-aws@amazon.com with the following subject line "Amazon Web Services – Email Address Verification Request in region {region you specified under the toml file}"
## 7. Run Snowflake scripts
  - In Snowflake console run the following Snowflake files in this order: load_data_to_snowflake.sql >> daily_load_to_s3_automated.sql
    - **NOTE:** Because the daily_load_to_s3_automated.sql is set to load at 4am EST you will not receive data in the input bucket immediately. Hence Airflow will not trigger. If you want to run Airflow now, change the task schedule in the daily_load_to_s3_automated.sql file to 'USING CRON * * * * * America/New_York' so that you receive data in the input bucket in a minute from now. The CRON expression "* * * * *" means that the task will run every minute. Airflow will only activate if the most current tables are in the data folder of the input bucket. However, make sure to change the task schedule in the daily_load_to_s3_automated.sql file to 'USING CRON 0 4 * * * America/New_York' and re-activate it again after you receive the data in the input bucket. The reason we change the cron frequency back to '0 4 * * *' is because running the task every minute will be very costly in the long run in Snowflake. 
## 8. Setup and Run Airflow
  - If you don't have Airflow set up in your EC2 instance,
    - Please go into the Airflow_EMR folder, run "chmod +x build_airflow_in_docker.sh" then run build_airflow_in_docker.sh
    - Otherwise just enter docker-compose up -d in the Airflow_EMR folder
  - Create a port forwarding connection for port 8080 (optional if you want to access locally)
  - In your browser url, enter {EC2 Public IPv4 address}:8080. This will lead you to the Airflow UI
  - In airflow, go to dags section. Then unpause the dag
  - Then go to Connections page and create a new Amazon Web Services connection with "Connection Id" named "aws_conn". Enter your access key and secret access key accordingly. Afterwards, in the "Extra" field, enter {"region_name": "{AWS region you set in config_file.toml}"}
  - In the Airflow_EMR folder, run "chmod +x trigger_airflow.sh"
  - Then run trigger_airflow.sh
## 9. Setup and Run Superset
  - Go into the Superset folder, run "chmod +x build_superset_in_docker.sh" then run build_superset_in_docker.sh
  - Create a port forwarding connection for port 8088
  - Paste in [http://localhost:8088/login/](http://localhost:8088/login/) to login
  - Create a new database by entering the following to connect Superset to Athena:
awsathena+rest://{aws access key}:{aws secret access key}@athena.{aws region}.amazonaws.com/?s3_staging_dir=s3://{output s3 bucket}/superset_metadata&work_group=primary
  - Add the necessary datasets in Superset
  - Build dashboards to your heart's content
## 10. Remove AWS Artifacts
  - Once you are done with the entire project, go into the Remove_AWS_Artifacts folder.
  - Then run "chmod +x remove_aws_artifacts.sh" and then run remove_aws_artifacts.sh
