#!/bin/bash
TARGET="$RUNNER_TEMP/slack-current-message.json"

if [ ! -f "$TARGET" ]; then
	cat "$GITHUB_ACTION_PATH/base.json" > "$TARGET"
fi

function update() {
	TEMP=$(mktemp)
	LABEL="*$1:*"
	VALUE="$2"

	jq --arg value "$VALUE" --arg lab "$LABEL" '( .[].fields[]? | select(.text | startswith($lab + "\n")) ).text |=  $lab + "\n" + $value' "$TARGET" > "$TEMP"
	cat "$TEMP" > "$TARGET"
	rm -rf "$TEMP"
}

if [ -n "$STATUS" ]; then
	update "Status" "$STATUS"
fi

if [ -n "$COMMIT_MESSAGE" ]; then
	update "Message" "$COMMIT_MESSAGE"
fi

if [ -n "$COMMIT_AUTHOR" ]; then
	update "Started by" "$COMMIT_AUTHOR"
fi

if [[ -n "$COMMIT_REPO" && -n "$COMMIT_BRANCH" ]]; then
	update "Repository" "$(printf "<https://github.com/%s|%s>" "$COMMIT_REPO" "$COMMIT_REPO")"
	update "Branch" "$(printf "<https://github.com/%s/tree/%s|%s>" "$COMMIT_REPO" "$COMMIT_BRANCH" "$COMMIT_BRANCH")"
fi


function get() {
	if [ -f "$1" ]; then
		cat "$1"
	fi

	echo -n "";
}

{
	echo "token=$(get "$RUNNER_TEMP/slack.token")"
	echo "channel=$(get "$RUNNER_TEMP/slack.channel")"
	echo "ts=$(get "$RUNNER_TEMP/slack.ts")"
	if [ -f "$RUNNER_TEMP/slack.ts" ]; then
		echo "function=update-message"
	else
		echo "function=send-message"
	fi

	echo 'blocks<<EOF_MANIFEST'
	cat "$TARGET"
	echo 'EOF_MANIFEST'
} >> "$GITHUB_OUTPUT"
