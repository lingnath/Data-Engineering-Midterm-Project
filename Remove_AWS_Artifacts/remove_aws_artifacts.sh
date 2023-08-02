#!/bin/bash

# Creates the log directory and logfiles within
filenametime=$(date +"%m%d%Y%H%M%S")
cd ..
log_dir="logs"
SHELL_SCRIPT_NAME='remove_aws_artifacts'

if [ ! -d $log_dir ]; then
    mkdir $log_dir
fi

LOG_FILE="${log_dir}/${SHELL_SCRIPT_NAME}_${filenametime}.log"
exec > >(tee "$LOG_FILE") 2>&1
cd "Remove_AWS_Artifacts/"

# Each section below consists of running a certain script and removing the created artifact. 
# Please enter "n" or "no" in the prompt so that AWS removes the artifacts accordingly. 
# The reason the prompts exist are in case you've already removed that particular artifact, giving
# you the choice to skip it where necessary. In that case, enter "y" or "yes" to skip that step
read -p "Have you removed the Glue crawler yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing Glue Crawler"
    sleep 3
    chmod +x remove_glue_crawler.sh
    ./remove_glue_crawler.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove the Glue crawler"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Glue crawler removed"
    fi
;;
esac

read -p "Have you removed the Glue role yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing Glue Role"
    sleep 3
    chmod +x remove_glue_role.sh
    ./remove_glue_role.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove the Glue role"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Glue role removed"
    fi
;;
esac

read -p "Have you removed the Athena database yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing Athena database"
    sleep 3
    chmod +x remove_athena_db.sh
    ./remove_athena_db.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove the Athena database"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Athena database removed"
    fi
;;
esac

read -p "Have you removed your email from SES yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing your email from SES"
    sleep 3
    chmod +x remove_ses_identity.sh
    ./remove_ses_identity.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove email from SES"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Your email has been removed from SES"
    fi
;;
esac

read -p "Have you removed the Lambda schedule trigger yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing Lambda schedule trigger and the rule"
    sleep 3
    chmod +x remove_lambda_schedule_trigger.sh
    ./remove_lambda_schedule_trigger.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove the Lambda schedule trigger"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Lambda schedule trigger removed"
    fi
;;
esac

read -p "Have you removed the Lambda layer yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing the Lambda layer"
    sleep 3
    chmod +x remove_lambda_layer.sh
    ./remove_lambda_layer.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove the Lambda layer"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Lambda layer removed"
    fi
;;
esac

read -p "Have you removed the Lambda function yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing the Lambda function"
    sleep 3
    chmod +x remove_lambda_function.sh
    ./remove_lambda_function.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove the Lambda function"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Lambda function removed"
    fi
;;
esac

read -p "Have you removed the Lambda role yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing the Lambda role"
    sleep 3
    chmod +x remove_lambda_role.sh
    ./remove_lambda_role.sh
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove the Lambda role"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "Lambda role removed"
    fi
;;
esac

read -p "Have you removed the S3 buckets yet? [y/n] " continue
case $continue in 
    "n"|"no"|"N"|"NO"|"No"|"nO")
    echo "Removing the Input and Output S3 buckets"
    sleep 3
    chmod +x remove_s3_buckets.py
    python3 remove_s3_buckets.py
    RC1=$?
    if [ $RC1 != 0 ]; then
        echo "Failed to remove the S3 buckets"
        echo "[ERROR:] RETURN CODE:  $RC1"
        echo "[ERROR:] REFER TO THE LOG FOR THE REASON FOR THE FAILURE."
        exit 1
    else
        echo "S3 buckets removed"
    fi
;;
esac