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
         - targets: ['$(hostname -I | awk '{print $1}'):9190']

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
