#!/bin/bash

# Only run this script if either this is your first time setting up this docker image for Airflow
# or if you are planning to rebuild the image again. Otherwise, there is no need to run this script.
# Therefore, if you've already built this particular image and have no intentions of rebuilding it again, 
# in the Airflow_EMR folder, just run "docker-compose up -d" to start Airflow and "docker-compose down" 
# to shut it down

# Get the airflow name prefix so that we can automatically get the container name later 
# without manually typing it in
airflow_name_prefix=$(pwd | rev | cut -d "/" -f 1 | rev | awk '{print tolower($0)}')

# Removing the folders so that there isn't an error if we rebuild the image again
for i in dags pgdata plugins
    do
    if [ -d $i ]; then
        sudo rm -r $i
    fi
    done

# Copy the config toml file into this folder so that Dockerfile can retrieve it
cp ../config_file.toml .

# Build docker airflow image and start container
docker-compose build

# Starts postgresql only
docker-compose up -d postgres

# Initialize database
docker-compose run --rm webserver airflow db init

# Start Webserver and Scheduler
docker-compose up -d

# Creating an account for Airflow so that we can login to access the UI
echo "Creating account for Airflow"
docker exec -it ${airflow_name_prefix}_webserver_1 airflow users create -u admin -p admin -f firstname -l lastname -r Admin -e admin@airflow.com
RC1=$?
if [ $RC1 != 0 ]; then
    echo "Failed to create account for Airflow"
    echo "[ERROR:] RETURN CODE:  $RC1"
    docker-compose down
    exit 1
fi

# Change ownership to ubuntu so that we can add and modify dags
sudo chown -R ubuntu:ubuntu dags/

# Removing the config file to prevent confusion with the config file in the main folder
rm config_file.toml

# Copying the dag python file into the dags folder so that Airflow detects and registers it
sudo cp dag_run.py dags/

# Restarting Airflow so that the DAG is reflected in the UI once we unpause it
docker-compose stop
echo "Waiting 10 seconds before restarting the Airflow Docker container"
sleep 10
docker-compose up -d

# Copying the .env file into the docker container
docker_container_name=${airflow_name_prefix}_scheduler_1
docker cp ../.env ${docker_container_name}:/opt/airflow/.env

# Making the airflow set up file executable
chmod +x airflow_ui_setup.sh

# Copying the airflow set up file into the docker container
docker cp airflow_ui_setup.sh ${docker_container_name}:/opt/airflow/airflow_ui_setup.sh

# Executing the airflow set up file 
docker exec ${docker_container_name} ./airflow_ui_setup.sh
