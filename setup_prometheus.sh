#!/bin/bash

# Create directories
sudo mkdir -p /home/pi/docker/prometheus
sudo mkdir -p /home/pi/docker/prometheus/prometheus_data
sudo mkdir -p /home/pi/docker/alertmanager/

# Create prometheus.yml file
echo "
# my global config
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.
  evaluation_interval: 15s # By default, scrape targets every 15 seconds.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'my-project'

# Load and evaluate rules in this file every 'evaluation_interval' seconds.
rule_files:
  - 'alert.rules'
  # - \"first.rules\"
  # - \"second.rules\"

# alert
alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - \"alertmanager:9093\"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label \`job=<job_name>\` to any timeseries scraped from this config.

  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 15s

    static_configs:
         - targets: ['\$(hostname -I | awk '{print \$1}')':9190']

  - job_name: 'cadvisor'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 15s

    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'node-exporter'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 15s

    static_configs:
      - targets: ['node-exporter:9100']
" | sudo tee /home/pi/docker/prometheus/prometheus.yml > /dev/null

# Set permissions
sudo chmod 777 -R /home/pi/docker
sudo chmod 777 -R /home/pi/docker/prometheus/
sudo chmod 777 -R /home/pi/docker/prometheus/prometheus_data/
sudo chmod 777 /home/pi/docker/prometheus/prometheus.yml

# Create docker-compose.yml file
echo "
version: '3.7'

volumes:
    prometheus_data: {}

networks:
  front-tier:
  back-tier:

services:

  prometheus:
    image: prom/prometheus:v2.36.2
    volumes:
      - /home/pi/docker/prometheus/:/etc/prometheus/
      - /home/pi/docker/prometheus/prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    ports:
      - 9190:9090
    links:
      - cadvisor:cadvisor
      - alertmanager:alertmanager
#      - pushgateway:pushgateway
    depends_on:
      - cadvisor
#      - pushgateway
    networks:
      - back-tier
    restart: always
#    deploy:
#      placement:
#        constraints:
#          - node.hostname == \${HOSTNAME}

  node-exporter:
    image: quay.io/prometheus/node-exporter:latest
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
      - /:/host:ro,rslave
    command: 
      - '--path.rootfs=/host'
      - '--path.procfs=/host/proc' 
      - '--path.sysfs=/host/sys'
      - --collector.filesystem.ignored-mount-points
      - \"^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)"
    ports:
      - 9100:9100
    networks:
      - back-tier
    restart: always
    deploy:
      mode: global

  alertmanager:
    image: prom/alertmanager
    ports:
      - 9093:9093
    volumes:
      - /home/pi/docker/alertmanager/:/etc/alertmanager/
    networks:
      - back-tier
    restart: always
    command:
      - '--config.file=/etc/alertmanager/config.yml'
      - '--storage.path=/alertmanager'
#    deploy:
#      placement:
#        constraints:
#          - node.hostname == \${HOSTNAME}

  cadvisor:
    image: gcr.io/cadvisor/cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    ports:
      - 8080:8080
    networks:
      - back-tier
    restart: always
    deploy:
      mode: global

#  pushgateway:
#    image: prom/pushgateway
#    restart: always
#    expose:
#      - 9091
#    ports:
#      - \"9091:9091\"
#    networks:
#      - back-tier
" | sudo tee /home/pi/docker/prometheus/docker-compose.yml > /dev/null

# Run Docker Compose
sudo docker-compose -f /home/pi/docker/prometheus/docker-compose.yml up -d
