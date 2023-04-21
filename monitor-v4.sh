#!/bin/bash

# Define the URLs to monitor
urls=(
      "https://dashboard-yarsabazaar.yarsa.games"
      "https://dashboard-yarsabazaar.yarsa.games/api"
      "https://dashboard.yarsabazar.com"
      "https://dashboard.yarsabazar.com/api"
      "http://localhost:8082"
      "http://localhost:9001"
      "https://www.google.com"
      "https://www.yahoo.com"
)

# Define the webhook URL to send notifications
webhook_url="enter_webhook_url from webhook.site"


# Define the file to store the server statuses
status_file="`$PWD`/server_statuses.txt"

# Define the colors for up and down statuses
#up_color="good"
#down_color="danger"

# Loop through the URLs
for url in "${urls[@]}"
do
  # Send a curl request to the URL
  response=$(curl -s -o /dev/null -w "%{http_code}" "$url")

  # Check if the status has changed
  if grep -q "$url" "$status_file"; then
    previous_status=$(grep "$url" "$status_file" | awk '{print $2}')
    if [[ "$response" == "$previous_status" ]]; then
      # Server status hasn't changed
      continue
    else
      # Server status has changed
      sed -i "s|$url.*|$url $response|g" "$status_file"
      if [[ "$response" == "200" || "$response" == "302" ]]; then
        # Server is up
        status="up"
        message="Server $url is back up!"
      else
        # Server is down
        status="down"
        message="Server $url is down!"
      fi
    fi
  else
    # Server status hasn't been recorded yet
    echo "$url $response" >> "$status_file"
    if [[ "$response" == "200" || "$response" == "302" ]]; then
      # Server is up
      status="up"
      message="Server $url is up!"
    else
      # Server is down
      status="down"
      message="Server $url is down!"
    fi
  fi

  # Send the notification
  if [[ "$status" == "up" ]]; then
    color="00FF00"
    title="Server is UP"
    icon="🟢"
  else
    color="FF0000"
    title="Server is DOWN"
    icon="🔴"
  fi
  current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  payload="{\"title\": \"$title\", \"text\": \"$message\", \"themeColor\": \"$color\", \"sections\": [{\"facts\": [{\"name\": \"$icon\", \"value\": \"\"},{\"name\": \"URL\", \"value\": \"$url\"},{\"name\": \"Time\", \"value\": \"$current_time\"}]}]}"
  curl -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url"
done
