#!/bin/bash

echo "Updating and upgrading packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing necessary packages..."
packages=("docker" "samba" "docker.io" "docker-compose" "telnet" "git" "lsof")

for package in "${packages[@]}"; do
  sudo apt install "$package" -y
done

echo "Running Portainer agent container..."
sudo docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  -v portainer_agent_data:/data \
  --restart always \
  -e EDGE=1 \
  -e EDGE_ID=$PORTAINER_EDGE_ID \
  -e EDGE_KEY=aHR0cHM6Ly9wb3J0YWluZXIubmV0LW5vdmljZS5jb218cG9ydGFpbmVyLm5ldC1ub3ZpY2UuY29tOjkwMDB8NDE6YmU6OTQ6N2M6ZDQ6YTY6Zjc6MGQ6YTg6MjE6NDI6ZGU6MDk6ZjU6ZjA6N2F8MA \
  -e EDGE_INSECURE_POLL=1 \
  --name portainer_edge_agent \
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
