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
docker exec ${folder_name}_scheduler_1 airflow dags trigger "$1"

# Wait until DAG finishes running
dag_id="$1"
stuck_check_interval=30
stuck_max_wait=300  # 5 minutes
stuck_wait=0

while true; do
    # Get the most recent DAG run's state (you may need to adjust for the exact DAG ID)
    DAG_STATUS=$(docker exec ${folder_name}_scheduler_1 airflow dags list-runs -d "$1" --output json | jq '.[0].state')
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

        # Begin stuck task check
        execution_date=$(docker exec ${folder_name}_scheduler_1 airflow dags list-runs -d "$dag_id" --output json | jq -r '.[0].execution_date')

        pending_tasks=$(docker exec ${folder_name}_scheduler_1 airflow tasks states-for-dag-run "$dag_id" "$execution_date" --output json | \
            jq -r '.[] | select(.state == "none" or .state == null or .state == "queued" or .state == "scheduled") | .task_id')

        running_count=$(docker exec ${folder_name}_scheduler_1 airflow tasks states-for-dag-run "$dag_id" "$execution_date" --output json | \
            jq '[.[] | select(.state == "running")] | length')

        success_count=$(docker exec ${folder_name}_scheduler_1 airflow tasks states-for-dag-run "$dag_id" "$execution_date" --output json | \
            jq '[.[] | select(.state == "success")] | length')

        echo "Pending tasks: $pending_tasks"
        echo "Running count: $running_count"
        echo "Success count: $success_count"

        if [[ -n "$pending_tasks" && $running_count -eq 0 && $success_count -gt 0 ]]; then
            echo "Potential stuck state: pending tasks exist, none running, some succeeded."
            stuck_wait=$((stuck_wait + stuck_check_interval))
        else
            echo "DAG is not stuck."
            stuck_wait=0  # Reset if progress is seen
        fi

        # If stuck for more than threshold, restart scheduler
        if [ $stuck_wait -ge $stuck_max_wait ]; then
            echo "Detected no progress for 5 minutes. Restarting Airflow scheduler..."
            pkill -f "airflow scheduler"
            sleep 5
            nohup airflow scheduler &
            echo "Scheduler restarted."
            stuck_wait=0  # Reset counter after restart
        fi

        sleep $stuck_check_interval
    fi
done

# Stop Airflow
docker-compose stop

# Stop EC2 instance
echo "Stopping EC2 instance"
python3 stop_ec2_instance.py
