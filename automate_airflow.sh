#!/bin/bash

cd /home/ubuntu
source airflow_env/bin/activate
folder_name="Airflow_EMR"
cd ${folder_name}

# Start Airflow
docker-compose up -d

# Poll until Airflow webserver and scheduler are running
echo "Waiting 60 seconds for Airflow webserver and scheduler to start..."
# Note to self: Find out how to dynamically check whether Airflow webserver and scheduler are done running
sleep 60

# Trigger DAG
docker exec ${folder_name}_webserver_1 airflow dags trigger "$1"

# Wait until DAG finishes running
while true; do
    # Get the most recent DAG run's state (you may need to adjust for the exact DAG ID)
    DAG_STATUS=$(docker exec ${folder_name}_webserver_1 airflow dags list-runs -d "$1" --output json | jq '.[0].state')
    DAG_STATUS=${DAG_STATUS//\"/}
    echo ${DAG_STATUS}

    if [ "$DAG_STATUS" == "success" ]; then
        echo "DAG run completed successfully!"
        break
    elif [ "$DAG_STATUS" == "failed" ]; then
        echo "DAG run failed."
        break
    else
        echo "DAG is still running..."
        sleep 10  # Wait for 10 seconds before checking again
    fi
done

# Stop Airflow
docker-compose stop

# Stop EC2 instance
echo "Stopping EC2 instance"
python3 stop_ec2_instance.py
