#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "Starting cron daemon for speedtest-monitor..."
# Start cron daemon using the 'service' command (common for Ubuntu-based images)
service cron start

# Give cron a moment to start up and potentially write something
sleep 5

# Ensure the log file exists before trying to tail it.
# This prevents 'No such file or directory' if cron hasn't written to it yet.
touch /var/log/speedtest_cron.log

echo "Monitoring speedtest cron logs... (Ctrl+C to stop)"
# Keep the container running indefinitely by tailing the cron log file.
# This is the main process that keeps the container alive.
tail -f /var/log/speedtest_cron.log