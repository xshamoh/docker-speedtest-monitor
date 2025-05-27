Dockerized Speedtest Monitor
This project provides a self-contained Docker Compose setup to regularly test your internet speed using Taganaka SpeedTest, store the results in InfluxDB, and visualize them in Grafana.

## Table of Contents

Features
Prerequisites
Project Structure
Getting Started
First-Time Setup (Build & Push)
Deployment on Any Machine (Pull & Run)
Accessing the Dashboard
Configuration
Troubleshooting
Customization
Features
Automated internet speed testing (Download, Upload, Ping, Jitter) every 2 minutes.
Uses Taganaka SpeedTest for measurements.
Stores data in InfluxDB 1.8.
Provides a pre-configured Grafana dashboard for visualization.
Easy deployment on multiple machines using Docker Compose and Docker Hub.
Prerequisites
Before you begin, ensure you have the following installed on your machine(s):

Git: For cloning the repository.
Docker Desktop (for Windows/macOS) or Docker Engine & Docker Compose (for Linux).
Project Structure
.
├── Dockerfile                      # Builds the speedtest-monitor image
├── docker-compose.yml              # Orchestrates InfluxDB, Grafana, and Speedtest Monitor
├── entrypoint.sh                   # Entrypoint script for the speedtest-monitor container
├── send_to_influxdb.sh             # Script to parse SpeedTest output and send to InfluxDB
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── influxdb.yml        # Grafana datasource configuration
│       └── dashboards/
│           ├── dashboard.yml       # Grafana dashboard provisioning
│           └── taganaka_speedtest_dashboard.json # The actual Grafana dashboard JSON
└── .gitignore                      # Specifies files/folders to ignore in Git
Getting Started
First-Time Setup (Build & Push)
Perform these steps on your development machine to build your custom Speedtest Monitor image and push it to Docker Hub, then deploy locally.

Clone this repository:
git clone https://github.com/xshamoh/docker-speedtest-monitor.git
cd C:\Users\shafiq01\Desktop\docker\SpeedTest
Build the speedtest-monitor Docker image:
docker build -t speedtest-monitor .
Log in to Docker Hub: docker login
Tag your image:
docker tag speedtest-monitor:latest xshamoh/speedtest-monitor:shafiq01
Push your image to Docker Hub:
docker push xshamoh/speedtest-monitor:shafiq01
Update docker-compose.yml: Modify the speedtest-monitor service in docker-compose.yml to use your pushed image:
YAML

  speedtest-monitor:
    # REMOVE OR COMMENT OUT THIS LINE:
    # build: .
    # ADD THIS LINE TO USE THE IMAGE FROM DOCKER HUB:
    image: xshamoh/speedtest-monitor:shafiq01
    # ... rest of the config ...
Commit and push the docker-compose.yml change to your Git repository:
git add docker-compose.yml
git commit -m "Update docker-compose.yml to use pushed custom image"
git push origin main # or master
Run Docker Compose locally:
docker-compose up -d

Deployment on Any Machine (Pull & Run)
Once your custom speedtest-monitor image is pushed to Docker Hub and your docker-compose.yml is updated in your Git repository, you can deploy this entire setup on any new machine.
Install Docker & Docker Compose (if not already installed).
Log in to Docker Hub: docker login
Clone your Git repository:
git clone https://github.com/xshamoh/docker-speedtest-monitor.git
cd <your_project_directory> (eg. C:\Users\shafiq01\Desktop\docker\SpeedTest)
Start the services:
docker-compose up -d
Accessing the Dashboard
Once all services are up and running (this might take a few minutes for InfluxDB and Grafana to initialize):
Open your web browser and go to: http://localhost:3000
The default Grafana login is admin/admin. You will be prompted to change the password upon first login.
The "Speedtest Results Dashboard" should be automatically provisioned and visible under the "Dashboards" section. Data points will start appearing every 2 minutes.

Configuration
Speedtest Interval: The cron job in Dockerfile (*/2 * * * * ...) runs every 2 minutes. Modify this line in the Dockerfile and rebuild/redeploy)
Speedtest server: --test-server speedtest.3.dk:8080 (change to another server if needed or remove and rebuild/redeploy)
InfluxDB Credentials: Modify docker-compose.yml (for the InfluxDB service environment variables) and grafana/provisioning/datasources/influxdb.yml (for Grafana's connection) if you change the default admin/password.
Speedtest Server: The SpeedTest binary by default selects the best server. You can modify entrypoint.sh or the cron job command in Dockerfile to specify a server using --test-server <server_url>.

Troubleshooting
Containers not starting:
Bash

docker-compose ps
docker-compose logs
No data in Grafana:
Check speedtest-monitor container logs: docker logs docker-speedtest-monitor-1. Look for Starting cron daemon and Monitoring speedtest cron logs.
Exec into the speedtest-monitor container and check the cron log:
Bash

docker exec -it docker-speedtest-monitor-1 tail -f /var/log/speedtest_cron.log
Look for curl: (7) Connection refused errors (check InfluxDB connection details) or parse errors from send_to_influxdb.sh.
Check InfluxDB health: docker ps should show (healthy) for the InfluxDB container.
check influxdb data:
docker exec -it docker-influxdb-1 /bin/bash
influx -host 0.0.0.0 -port 8086 -database speedtest
SELECT * FROM taganaka_speed ORDER BY DESC LIMIT 10
check epoch time on eg https://www.epochconverter.com/
Customization
Modify Taganaka SpeedTest: If you wish to use a modified version of Taganaka SpeedTest, change the RUN git clone ... line in the Dockerfile to COPY SpeedTest/ . and place your modified source in a SpeedTest/ subdirectory. Remember to rebuild and push your image.
Grafana Dashboard: You can customize the taganaka_speedtest_dashboard.json file to change how data is visualized. Changes will be applied on container restart due to provisioning.

