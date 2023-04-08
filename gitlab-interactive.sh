#!/bin/bash

# Set the GitLab server URL, project ID, and access token
GITLAB_URL="https://gitlab.example.com"
PROJECT_ID="123"
ACCESS_TOKEN="your_access_token_here"

# Prompt the user to choose an action to perform
echo "What action do you want to perform?"
echo "1. Close issues"
echo "2. Label issues"
echo "3. Assign issues"
read -p "Enter the number of the action to perform: " ACTION

# Perform the chosen action
case $ACTION in
  1)
    # Prompt the user to enter a comma-separated list of issue numbers to close
    read -p "Enter the issue numbers to close (comma-separated): " ISSUE_NUMBERS

    # Send a PUT request to the GitLab API to close the specified issues
    for ISSUE_NUMBER in $(echo $ISSUE_NUMBERS | sed "s/,/ /g"); do
      curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$GITLAB_URL/api/v4/projects/$PROJECT_ID/issues/$ISSUE_NUMBER?state_event=close"
      echo "Issue #$ISSUE_NUMBER has been closed."
    done
    ;;
  2)
    # Prompt the user to enter a comma-separated list of issue numbers to label
    read -p "Enter the issue numbers to label (comma-separated): " ISSUE_NUMBERS

    # Prompt the user to enter a comma-separated list of labels to apply
    read -p "Enter the labels to apply (comma-separated): " LABELS

    # Send a PUT request to the GitLab API to add the specified labels to each of the specified issues
    for ISSUE_NUMBER in $(echo $ISSUE_NUMBERS | sed "s/,/ /g"); do
      curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN" --header "Content-Type: application/json" --data "{\"add_labels\": [$(echo $LABELS | sed "s/,/\",\"/g")]}" "$GITLAB_URL/api/v4/projects/$PROJECT_ID/issues/$ISSUE_NUMBER"
      echo "Labels \"$LABELS\" have been added to issue #$ISSUE_NUMBER."
    done
    ;;
  3)
    # Prompt the user to enter a comma-separated list of issue numbers to assign
    read -p "Enter the issue numbers to assign (comma-separated): " ISSUE_NUMBERS

    # Prompt the user to enter a comma-separated list of usernames to assign
    read -p "Enter the usernames to assign (comma-separated), or leave blank to unassign the current user: " USERNAMES

    # Determine the user ID of each specified username
    USER_IDS=""
    if [ -n "$USERNAMES" ]; then
      for USERNAME in $(echo $USERNAMES | sed "s/,/ /g"); do
        USER_ID=$(curl --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$GITLAB_URL/api/v4/users?username=$USERNAME" | jq -r '.[].id')
        if [ -z "$USER_ID" ]; then
          echo "User \"$USERNAME\" not found."
          exit 1
        fi
        USER_IDS="$USER_IDS $USER_ID"
      done
    fi

    # Send a PUT request to the GitLab API to assign or unassign the specified users from each of the specified issues
    for ISSUE_NUMBER in $(echo $ISSUE_NUMBERS | sed "s/,/ /g"); do
      if [ -z "$USER_IDS" ]; then
        curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN" --header "Content-Type: application/json" --data '{"assignee_id": null}' "$GITLAB_URL/api/v4/projects/$PROJECT_ID/issues/$ISSUE_NUMBER"
        echo "The assignee has been removed from issue #$ISSUE_NUMBER."
      else
        curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN" --header "Content-Type: application/json" --data "{\"assignee_ids\": [$(echo $USER_IDS | sed "s/ /,/g")]}" "$GITLAB_URL/api/v4/projects/$PROJECT_ID/issues/$ISSUE_NUMBER"
        echo "The following users have been assigned to issue #$ISSUE_NUMBER: \"$USERNAMES\"."
      fi
    done
    ;;
esac
