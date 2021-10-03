#!/usr/bin/env bash

# Get current branch
branch=$(cd "$GITPOD_REPO_ROOT" && git symbolic-ref --short -q HEAD)

# Check the status of ready-made envs file
# https://stackoverflow.com/a/53358157/5754049
url_status=$(wget --server-response --spider --quiet "${DP_READY_MADE_ENVS_URL}" 2>&1 | awk 'NR==1{print $2}')

# If there's a problem send the error code
if [ "$url_status" = '200' ]; then
    message="100%"
else
    message="Error: $url_status - $DP_READY_MADE_ENVS_URL"
fi

# Send a message through IFTTT
curl -X POST -H "Content-Type: application/json" -d "{\"value1\":\"$branch\",\"value2\":\"$message\"}" https://maker.ifttt.com/trigger/drupalpod_prebuild_initiated/with/key/"$IFTTT_TOKEN"