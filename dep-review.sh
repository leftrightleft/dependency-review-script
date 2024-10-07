#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <org_name> <repo_name> <base> <head> <severity_threshold>"
  exit 1
fi

# Assign input arguments to variables
ORG_NAME=$1
REPO_NAME=$2
BASE=$3
HEAD=$4
SEVERITY_THRESHOLD=$5

# Define severity levels in order of increasing severity
SEVERITY_LEVELS=("low" "medium" "high" "critical")

# Function to get the index of a severity level
get_severity_index() {
  local severity=$1
  for i in "${!SEVERITY_LEVELS[@]}"; do
    if [[ "${SEVERITY_LEVELS[$i]}" == "$severity" ]]; then
      echo $i
      return
    fi
  done
  echo -1
}

# Function to URL encode a string
urlencode() {
  local string="$1"
  local encoded=""
  local length="${#string}"
  for (( i = 0; i < length; i++ )); do
    local c="${string:i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) encoded+="$c" ;;
      *) encoded+=$(printf '%%%02X' "'$c") ;;
    esac
  done
  echo "$encoded"
}

# URL encode org_name, repo_name, base, and head
ENCODED_ORG_NAME=$(urlencode "$ORG_NAME")
ENCODED_REPO_NAME=$(urlencode "$REPO_NAME")
ENCODED_BASE=$(urlencode "$BASE")
ENCODED_HEAD=$(urlencode "$HEAD")

# Get the index of the severity threshold
THRESHOLD_INDEX=$(get_severity_index "$SEVERITY_THRESHOLD")

# Construct the API URL
API_URL="https://api.github.com/repos/$ORG_NAME/$REPO_NAME/dependency-graph/compare/$ENCODED_BASE...$ENCODED_HEAD"

# Make the API request and capture the HTTP status code
HTTP_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "$API_URL")

# Extract the body and the status code
HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -e 's/HTTPSTATUS\:.*//g')
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

# Log the response data
echo "API Response: $HTTP_BODY"

# Check if the request was successful
if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "Error: Received HTTP status code $HTTP_STATUS"
  exit 1
fi

# Check for vulnerabilities in the response
VULNERABILITIES=$(echo "$HTTP_BODY" | jq -c '.[] | select(.vulnerabilities | length > 0) | .vulnerabilities[]')

# If no vulnerabilities are found, print a message and exit
if [ -z "$VULNERABILITIES" ]; then
  echo "No vulnerabilities found"
  exit 0
fi

# Iterate over each vulnerability and check its severity
echo "$VULNERABILITIES" | jq -c '.' | while read -r vulnerability; do
  echo "Processing vulnerability: $vulnerability"
  SEVERITY=$(echo "$vulnerability" | jq -r '.severity')
  SEVERITY_INDEX=$(get_severity_index "$SEVERITY")

  echo "Severity: $SEVERITY, Index: $SEVERITY_INDEX, Threshold Index: $THRESHOLD_INDEX"

  if [ "$SEVERITY_INDEX" -ge "$THRESHOLD_INDEX" ]; then
    echo "Vulnerability found with severity $SEVERITY!"
    exit 1
  else
    echo "No vulnerabilities found that meet or exceed the severity threshold."
    exit 0
  fi
done
