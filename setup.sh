#!/bin/bash

echo "Updating and upgrading packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing necessary packages..."
sudo apt install docker samba docker.io docker-compose -y

echo "Running Portainer agent container..."
sudo docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  portainer/agent:2.18.3

echo "Script execution completed."
