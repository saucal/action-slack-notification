#!/bin/bash

set -e

FILE_PATH="$1"
FILENAME=$(basename "$FILE_PATH")
FILE_SIZE=$(stat -c%s "$FILE_PATH")

# Step 1: Get upload URL
UPLOAD_URL_RESPONSE=$(curl -s -X POST "https://slack.com/api/files.getUploadURLExternal" \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  -F "filename=$FILENAME" \
  -F "length=$FILE_SIZE"
)

UPLOAD_URL=$(echo "$UPLOAD_URL_RESPONSE" | jq -r '.upload_url')
FILE_ID=$(echo "$UPLOAD_URL_RESPONSE" | jq -r '.file_id')

if [ -z "$UPLOAD_URL" ] || [ "$UPLOAD_URL" == "null" ] || [ -z "$FILE_ID" ] || [ "$FILE_ID" == "null" ]; then
  echo "Error getting upload URL:"
  echo "$UPLOAD_URL_RESPONSE"
  exit 1
fi

# Step 2: Upload file content
curl -s -X POST --data-binary "@$FILE_PATH" "$UPLOAD_URL"

# Step 3: Complete upload
FILES_JSON=$(jq -n -c --arg id "$FILE_ID" --arg title "$FILENAME" '[{id: $id, title: $title}]')

curl -s -X POST "https://slack.com/api/files.completeUploadExternal" \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  -F "files=$FILES_JSON" \
  -F "channel_id=$SLACK_CHANNEL" \
  -F "initial_comment=$INITIAL_COMMENT" \
  -F "thread_ts=$SLACK_TS"
