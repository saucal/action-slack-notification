# Slack build notification

This action will post a notification to a Slack channel, and subsequent calls to this action can update that notification to reflect a new status.

## Getting Started

To set up the action and send the first message, you can do the following:

```yml
- name: Prepare
  uses: saucal/action-slack-notification@v1
  with:
    token: "SLACK_BOT_TOKEN"
    channel: "XXXXXXX"
    status: 'Preparing :loading:'
    commit-repo: "${{ github.repository }}"
    commit-branch: ${{ github.ref_name }}
    commit-author: ${{ github.triggering_actor }}
    commit-message: "..."
```

After, you can run something like follows, to update the status of the build

```yml
- name: Set message
  uses: saucal/action-slack-notification@v1
  with:
    status: "Building :large_yellow_circle:"
```

And finally, after you're done, you can signal the final status as follows

```yml
- name: Signal final status to slack
  if: ${{ always() }} # THIS IS KEY!
  uses: saucal/action-slack-notification@v1
  with:
    final-status: "${{ job.status }}"
```

## Full options

```yml
- uses: saucal/action-slack-notification@v1
  with:
    # Slack Token to use
    token: ""

    # Channel to post to
    channel: ""

    # Message timestamp to update
    ts: ""

    # Force send a new message (even if we're already in update mode)
    # NOTE: Subsequent calls to the action will update the new one.
    force: "false"

    # Set status of the deployment. Supports emojis.
    status: ""

    # Similar to the above, but serves as a parsing point for GH job status strings
    final-status: ""

    # Set commit message on the notification
    commit-message: ""

    # Set branch on the notification
    commit-branch: ""

    # Set repo on the notification
    commit-repo: ""

    # Set author on the notification
    commit-author: ""
```
