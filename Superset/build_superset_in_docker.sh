#!/bin/bash

# Only run this script if either this is your first time building the docker image for Superset.
# Or if you want to rebuild another image for a new container. Otherwise, just run the command
# docker start {superset_container_name} and consequently docker stop {superset_container_name}
# when starting and stopping Superset respectively
superset_container_name=$(cat ../config_file.toml | grep 'container_name' | awk -F"=" '{print $2}' | tr -d "'")

docker pull stantaov/superset-athena:0.0.1
# Setting the port to be 8088 so that it doesn't conflict with port 8080 that Airflow runs on
docker run -d -p 8088:8088 --name ${superset_container_name} stantaov/superset-athena:0.0.1
docker exec -it ${superset_container_name} superset fab create-admin \
               --username admin \
               --firstname Superset \
               --lastname Admin \
               --email admin@superset.com \
               --password admin
docker exec -it ${superset_container_name} superset db upgrade
docker exec -it ${superset_container_name} superset init