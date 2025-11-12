#!/bin/bash

set -e

FILE_PATH="$1"

# Validate that the file exists and is readable
if [ ! -e "$FILE_PATH" ]; then
  echo "Error: File '$FILE_PATH' does not exist."
  exit 1
fi
if [ ! -r "$FILE_PATH" ]; then
  echo "Error: File '$FILE_PATH' is not readable."
  exit 1
fi
FILENAME=$(basename "$FILE_PATH")
FILE_SIZE=$(wc -c < "$FILE_PATH" | tr -d '[:space:]')

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
UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST --data-binary "@$FILE_PATH" "$UPLOAD_URL")
UPLOAD_BODY=$(echo "$UPLOAD_RESPONSE" | head -n -1)
UPLOAD_STATUS=$(echo "$UPLOAD_RESPONSE" | tail -n1)

if [ "$UPLOAD_STATUS" -lt 200 ] || [ "$UPLOAD_STATUS" -ge 300 ]; then
  echo "Error uploading file (HTTP $UPLOAD_STATUS):"
  echo "$UPLOAD_BODY"
  exit 1
fi
# Step 3: Complete upload
FILES_JSON=$(jq -n -c --arg id "$FILE_ID" --arg title "$FILENAME" '[{id: $id, title: $title}]')

COMPLETE_RESPONSE=$(curl -s -X POST "https://slack.com/api/files.completeUploadExternal" \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  -F "files=$FILES_JSON" \
  -F "channel_id=$SLACK_CHANNEL" \
  -F "initial_comment=$INITIAL_COMMENT" \
  -F "thread_ts=$SLACK_TS")

OK=$(echo "$COMPLETE_RESPONSE" | jq -r '.ok')
if [ "$OK" != "true" ]; then
  echo "Error completing file upload:"
  echo "$COMPLETE_RESPONSE"
  exit 1
fi
