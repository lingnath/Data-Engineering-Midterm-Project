#!/bin/bash

# Only run this script if either this is your first time building the docker image for Airflow
# or if you are planning to rebuild the image again. Otherwise, there is no need to run this script
# as you will need to set up all the connections and dags again in the Airflow UI.
# Therefore, if you've already built your image and have no intentions of rebuilding it again, 
# just run "docker-compose up -d" to start Airflow and "docker-compose down" to shut it down

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
docker-compose up -d

# Upgrades and initializes the Airflow database
echo "Upgrading airflow database"
docker exec -it ${airflow_name_prefix}_webserver_1 airflow db upgrade

echo "Initializing airflow database"
docker exec -it ${airflow_name_prefix}_webserver_1 airflow db init
RC1=$?
if [ $RC1 != 0 ]; then
    echo "Failed to initialize airflow database"
    echo "[ERROR:] RETURN CODE:  $RC1"
    docker-compose down
    exit 1
fi

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

# Removing the config file to prevent confusion with the config file in the main folder. 
# We want to make sure there is only one source of truth
rm config_file.toml

# Copying the dag python file into the dags folder so that Airflow detects and registers it
sudo cp dag_run.py dags/