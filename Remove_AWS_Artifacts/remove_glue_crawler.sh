#!/bin/bash

aws_region=$(cat ../config_file.toml | grep 'region' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")
glue_crawler_name=$(cat ../config_file.toml | grep 'glue_crawler_name' | awk -F "=" '{print $2}' | tr -d "'" | tr -d " ")

# Deletes the glue crawlers for each of the tables (calendar, fact, product, and store tables)
for table in calendar fact product store;
do 
aws glue delete-crawler --name ${glue_crawler_name}_${table} \
 --region ${aws_region}
done;
