# Dockerized Speedtest Monitor

This project provides a self-contained Docker Compose setup to regularly test your internet speed using Taganaka SpeedTest, store the results in InfluxDB, and visualize them in Grafana.

## Table of Contents

-   [Features](#features)
-   [Prerequisites](#prerequisites)
-   [Project Structure](#project-structure)
-   [Getting Started](#getting-started)
    -   [First-Time Setup (Build & Push)](#first-time-setup-build--push)
    -   [Deployment on Any Machine (Pull & Run)](#deployment-on-any-machine-pull--run)
-   [Accessing the Dashboard](#accessing-the-dashboard)
-   [Configuration](#configuration)
-   [Troubleshooting](#troubleshooting)
-   [Customization](#customization)

## Features

* Automated internet speed testing (Download, Upload, Ping, Jitter) every 2 minutes.
* Uses [Taganaka SpeedTest](https://github.com/taganaka/SpeedTest) for measurements.
* Stores data in InfluxDB 1.8.
* Provides a pre-configured Grafana dashboard for visualization.
* Easy deployment on multiple machines using Docker Compose and Docker Hub.

## Prerequisites

Before you begin, ensure you have the following installed on your machine(s):

* **Git:** For cloning the repository.
* **Docker Desktop** (for Windows/macOS) or **Docker Engine & Docker Compose** (for Linux).

## Project Structure

This project contains the following key files and directories:

* `Dockerfile`: Builds the custom `speedtest-monitor` Docker image.
* `docker-compose.yml`: Orchestrates the InfluxDB, Grafana, and Speedtest Monitor services.
* `entrypoint.sh`: The entrypoint script for the `speedtest-monitor` container.
* `send_to_influxdb.sh`: Script to parse SpeedTest output and send data to InfluxDB.
* `grafana/`: Directory containing Grafana provisioning files.
    * `grafana/provisioning/datasources/influxdb.yml`: Configures the InfluxDB data source in Grafana.
    * `grafana/provisioning/dashboards/dashboard.yml`: Provisions the custom dashboard in Grafana.
    * `grafana/provisioning/dashboards/taganaka_speedtest_dashboard.json`: The JSON definition of the Grafana dashboard.
* `.gitignore`: Specifies files/folders that Git should ignore.

## Getting Started

### First-Time Setup (Build & Push)

Perform these steps on your development machine to build your custom Speedtest Monitor image and push it to Docker Hub, then deploy locally.

1.  **Clone this repository:**
    ```bash
    git clone [https://github.com/xshamoh/docker-speedtest-monitor.git](https://github.com/xshamoh/docker-speedtest-monitor.git)
    cd <your_project_directory> # e.g., cd C:\Users\shafiq01\Desktop\docker
    ```
2.  **Build the `speedtest-monitor` Docker image:**
    ```bash
    docker build -t speedtest-monitor .
    ```
3.  **Log in to Docker Hub:**
    ```bash
    docker login
    ```
4.  **Tag your image:**
    ```bash
    docker tag speedtest-monitor:latest xshamoh/speedtest-monitor:shafiq01
    ```
5.  **Push your image to Docker Hub:**
    ```bash
    docker push xshamoh/speedtest-monitor:shafiq01
    ```
6.  **Update `docker-compose.yml`:**
    Modify the `speedtest-monitor` service in `docker-compose.yml` to use your pushed image:
    ```yaml
      speedtest-monitor:
        # REMOVE OR COMMENT OUT THIS LINE:
        # build: .
        # ADD THIS LINE TO USE THE IMAGE FROM DOCKER HUB:
        image: xshamoh/speedtest-monitor:shafiq01
        # ... rest of the config ...
    ```
7.  **Commit and push the `docker-compose.yml` change to your Git repository:**
    ```bash
    git add docker-compose.yml
    git commit -m "Update docker-compose.yml to use pushed custom image"
    git push origin main # or master
    ```
8.  **Run Docker Compose locally:**
    ```bash
    docker-compose up -d
    ```

### Deployment on Any Machine (Pull & Run)

Once your custom `speedtest-monitor` image is pushed to Docker Hub and your `docker-compose.yml` is updated in your Git repository, you can deploy this entire setup on any new machine.

1.  **Install Docker & Docker Compose** (if not already installed).
2.  **Log in to Docker Hub:**
    ```bash
    docker login
    ```
3.  **Clone your Git repository:**
    ```bash
    git clone [https://github.com/xshamoh/docker-speedtest-monitor.git](https://github.com/xshamoh/docker-speedtest-monitor.git)
    cd <your_project_directory> # e.g., cd C:\Users\shafiq01\Desktop\docker
    ```
4.  **Start the services:**
    ```bash
    docker-compose up -d
    ```

## Accessing the Dashboard

Once all services are up and running (this might take a few minutes for InfluxDB and Grafana to initialize):

* Open your web browser and go to: `http://localhost:3000`
* The default Grafana login is `admin`/`admin`. You will be prompted to change the password upon first login.
* The "Speedtest Results Dashboard" should be automatically provisioned and visible under the "Dashboards" section. Data points will start appearing every 2 minutes.

## Configuration

* **Speedtest Interval:** The cron job in `Dockerfile` (`*/2 * * * * ...`) runs every 2 minutes. Modify this line in the `Dockerfile` and rebuild/redeploy if you want a different interval.
* **Speedtest Server:** The `SpeedTest` binary by default selects the best server. You can modify `entrypoint.sh` or the cron job command in `Dockerfile` to specify a server, e.g., using `--test-server speedtest.3.dk:8080`. Remember to rebuild and redeploy after changes.
* **InfluxDB Credentials:** Modify `docker-compose.yml` (for the InfluxDB service environment variables) and `grafana/provisioning/datasources/influxdb.yml` (for Grafana's connection) if you change the default `admin`/`password`.

## Troubleshooting

* **Containers not starting:**
    ```bash
    docker-compose ps
    docker-compose logs
    ```
* **No data in Grafana:**
    * Check `speedtest-monitor` container logs: `docker logs docker-speedtest-monitor-1`. Look for `Starting cron daemon` and `Monitoring speedtest cron logs`.
    * Exec into the `speedtest-monitor` container and check the cron log:
        ```bash
        docker exec -it docker-speedtest-monitor-1 tail -f /var/log/speedtest_cron.log
        ```
        Look for `curl: (7) Connection refused` errors (check InfluxDB connection details) or parse errors from `send_to_influxdb.sh`.
    * Check InfluxDB health: `docker ps` should show `(healthy)` for the InfluxDB container.
    * Check InfluxDB data directly:
        ```bash
        docker exec -it docker-influxdb-1 /bin/bash
        influx -host 0.0.0.0 -port 8086 -database speedtest
        SELECT * FROM taganaka_speed ORDER BY DESC LIMIT 10
        ```
    * Verify epoch time if data seems off (e.g., using [https://www.epochconverter.com/](https://www.epochconverter.com/)).

## Customization

* **Modify Taganaka SpeedTest:** If you wish to use a modified version of Taganaka SpeedTest, change the `RUN git clone ...` line in the `Dockerfile` to `COPY SpeedTest/ .` and place your modified source in a `SpeedTest/` subdirectory. Remember to rebuild and push your image.
* **Grafana Dashboard:** You can customize the `taganaka_speedtest_dashboard.json` file to change how data is visualized. Changes will be applied on container restart due to provisioning.