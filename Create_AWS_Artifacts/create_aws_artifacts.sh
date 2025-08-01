#!/bin/bash

# Creates the log directory and logfiles within
filenametime=$(date +"%m%d%Y%H%M%S")
cd ..
log_dir="logs"
SHELL_SCRIPT_NAME='create_aws_artifacts'

if [ ! -d $log_dir ]; then
    mkdir $log_dir
fi

LOG_FILE="${log_dir}/${SHELL_SCRIPT_NAME}_${filenametime}.log"
# exec > >(tee "$LOG_FILE") 2>&1
exec > "$LOG_FILE" 2>&1
cd "Create_AWS_Artifacts/"

# Each section below consists of running a certain script and creating a new artifact. 
# Please enter "n" or "no" in the prompt so that AWS creates the artifacts accordingly. 
# The reason the prompts exist are in case you've already created that particular artifact, giving
# you the choice to skip it where necessary. In that case, enter "y" or "yes" to skip that step
read -p "Have you created the S3 buckets yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating the Input and Output S3 buckets and folders within"
    sleep 3
    chmod +x create_s3_buckets.py
    python3 create_s3_buckets.py
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create the S3 buckets"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "S3 buckets created"
    fi
;;
esac

read -p "Have you created a Lambda role yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating the Lambda role and attaching appropriate permissions"
    sleep 3
    chmod +x create_lambda_role.sh
    ./create_lambda_role.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create a Lambda role"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Lambda role created"
    fi
;;
esac

read -p "Have you created a Lambda layer yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating the Lambda layer"
    sleep 3
    chmod +x create_lambda_layer.sh
    ./create_lambda_layer.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create a Lambda layer"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Lambda layer created"
    fi
;;
esac

read -p "Have you created a Lambda function yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating the Lambda function"
    sleep 3
    chmod +x create_lambda_function.sh
    ./create_lambda_function.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create a Lambda function"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Lambda function created"
    fi
;;
esac

read -p "Have you created a Lambda schedule trigger yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Attaching a schedule trigger to Lambda so that it runs at midnight"
    sleep 3
    chmod +x create_lambda_schedule_trigger.sh
    ./create_lambda_schedule_trigger.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create a Lambda schedule trigger"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Lambda schedule trigger created"
    fi
;;
esac

read -p "Have you created an EMR role yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating EMR role"
    sleep 3
    chmod +x create_emr_role.sh
    ./create_emr_role.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create an EMR role"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "EMR role created"
    fi
;;
esac

read -p "Have you registered your email that you plan to send with SES yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating email verification with SMS"
    sleep 3
    chmod +x create_ses_identity.sh
    ./create_ses_identity.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create EMR verification with SMS"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "SES identity created. Please verify by checking your email for a message from AWS"
    fi
;;
esac

read -p "Have you created an Athena database yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating Athena database"
    sleep 3
    chmod +x create_athena_db.sh
    ./create_athena_db.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create Athena database"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Athena database created"
    fi
;;
esac

read -p "Have you created a Glue role yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating Glue role"
    sleep 3
    chmod +x create_glue_role.sh
    ./create_glue_role.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create Glue role"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Glue role created"
    fi
;;
esac

read -p "Have you created a Glue crawler yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Creating Glue Crawler"
    sleep 3
    chmod +x create_glue_crawler.sh
    ./create_glue_crawler.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to create Glue crawler"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Glue crawler created"
    fi
;;
esac
