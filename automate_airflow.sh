#!/bin/bash

cd /home/ubuntu
source Software_Installations/python_env/bin/activate
folder_name="airflow_emr"
cd ${folder_name}

# Start Airflow
docker-compose up -d

# Ensure scheduler is actually healthy and processing DAGs
check_scheduler_heartbeat() {
    scheduler_heartbeat=$(docker exec -it ${folder_name}_scheduler_1 airflow jobs check --job-type SchedulerJob 2>&1)
    if [[ "$scheduler_heartbeat" != *"No alive"* ]]; then
        return 0
    else
        return 1
    fi
}

echo "Checking Airflow scheduler heartbeat..."
while ! check_scheduler_heartbeat; do
    echo "Waiting for scheduler to become alive..."
    sleep 10
done

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
