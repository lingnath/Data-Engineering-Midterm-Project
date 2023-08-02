#!/bin/bash

# Please replace apt-get with yum if you are using Amazon AMI, which uses RHEL
sudo apt-get update
sudo apt-get install curl -y
curl --version
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.4/docker-compose-Linux-x86_64" -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
docker-compose --version