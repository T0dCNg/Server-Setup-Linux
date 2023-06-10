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

echo "Waiting for Portainer agent to start..."
sleep 5

echo "Retrieving Portainer agent key..."
AGENT_KEY=$(sudo docker logs portainer_agent 2>&1 | grep "Please register this agent" | awk '{print $NF}')

echo "Registering device as an agent..."
RESPONSE=$(curl -X POST \
  --header 'Content-Type: application/json' \
  --data "{\"Name\":\"My Device\",\"URL\":\"http://localhost:9001\",\"EndpointID\":\"$AGENT_KEY\"}" \
  http://10.20.4.173:9000/api/agent_instances)

if [[ $RESPONSE == *"Error"* ]]; then
  echo "Error occurred while registering the device as an agent:"
  echo $RESPONSE
else
  echo "Device successfully registered as an agent!"
fi

echo "Script execution completed."
