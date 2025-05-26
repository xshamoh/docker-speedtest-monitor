# Use Ubuntu 22.04 as the base image for consistent compatibility
FROM ubuntu:22.04

# Set environment variables for non-interactive apt operations
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install necessary packages for building SpeedTest and running cron:
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    git \
    build-essential \
    cron \
    wget \
    libcurl4-openssl-dev \
    libxml2-dev \
    libssl-dev \
    libxml2 \
    libcurl4 \
    cmake \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# --- Taganaka SpeedTest Setup ---
# Create a dedicated directory for the SpeedTest source inside the container
WORKDIR /tmp/SpeedTestSource

# Reverted: Clone the taganaka repository directly from GitHub
# This allows the image to pull the latest official changes at build time.
RUN git clone https://github.com/taganaka/SpeedTest.git .

# Compile SpeedTest
# This sequence runs cmake to generate build files and then make to compile the binary.
RUN mkdir build \
    && cd build \
    && cmake .. \
    && make

# Create the final application directory and copy the compiled binary into it
RUN mkdir -p /app/speedtest
# The compiled binary is in /tmp/SpeedTestSource/build/SpeedTest after the above steps
RUN cp /tmp/SpeedTestSource/build/SpeedTest /app/speedtest/SpeedTest

# --- Cron Job Setup ---
COPY send_to_influxdb.sh /app/speedtest/send_to_influxdb.sh

RUN chmod +x /app/speedtest/SpeedTest \
    && chmod +x /app/speedtest/send_to_influxdb.sh

# Add the cron job for the root user.
# CORRECTED PATH: Ensure there's only one "/app/" before "/speedtest/" for send_to_influxdb.sh
RUN (crontab -l 2>/dev/null; echo "*/2 * * * * /app/speedtest/SpeedTest --test-server speedtest.3.dk:8080 | /app/speedtest/send_to_influxdb.sh >> /var/log/speedtest_cron.log 2>&1") | crontab -

# --- Entrypoint Script ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports (not strictly necessary for this service in compose, but doesn't hurt)
EXPOSE 3000
EXPOSE 8086

# Set the entrypoint for the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]