#!/bin/bash

# InfluxDB connection details (adjust if needed)
INFLUXDB_HOST="influxdb"
INFLUXDB_PORT="8086"
INFLUXDB_DATABASE="speedtest"
INFLUXDB_USER="admin"
INFLUXDB_PASSWORD="password"

# Parse Taganaka's verbose/TXT output using awk
speedtest_output=$(cat) # Read all input

download_mbps=$(echo "$speedtest_output" | awk '/Download:/ {gsub(/[^0-9.]/, "", $2); print $2}')
upload_mbps=$(echo "$speedtest_output" | awk '/Upload:/ {gsub(/[^0-9.]/, "", $2); print $2}')
ping=$(echo "$speedtest_output" | awk '/Ping:/ {gsub(/[^0-9.]/, "", $2); print $2}')
jitter=$(echo "$speedtest_output" | awk '/Jitter:/ {gsub(/[^0-9.]/, "", $2); print $2}')

# Initialize InfluxDB line protocol data
influx_data="taganaka_speed,host=docker_container download=${download_mbps}" # Changed host tag for clarity

# Add other fields only if they have values
if [ -n "$upload_mbps" ]; then
    influx_data="${influx_data},upload=${upload_mbps}"
fi

if [ -n "$ping" ]; then
    influx_data="${influx_data},ping=${ping}"
fi

if [ -n "$jitter" ]; then
    influx_data="${influx_data},jitter=${jitter}"
fi

# Send data to InfluxDB 1.x
curl -i -XPOST "http://${INFLUXDB_HOST}:${INFLUXDB_PORT}/write?db=${INFLUXDB_DATABASE}&u=${INFLUXDB_USER}&p=${INFLUXDB_PASSWORD}" \
    --data "$influx_data"

echo "Data sent to InfluxDB from WSL2"