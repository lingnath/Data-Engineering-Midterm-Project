#!/bin/bash
sudo apt-get update
sudo apt-get install python3.10 -y
sudo apt-get install pip -y
sudo apt install python3.10-venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
jupyter notebook
