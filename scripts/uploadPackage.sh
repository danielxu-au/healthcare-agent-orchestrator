#!/bin/bash

# Parameters
directory="$1"
chatOrLink="$2"
tenantId="$3"

# Arg check
if [ -z "$directory" ] || [ -z "$chatOrLink" ]; then
  echo "Usage: $0 <directory> <teamsChatId|meetingLink> [tenantId]"
  exit 1
fi

# ---------------------------------------------------------------------
# Detect whether $chatOrLink is a URL or a bare ID
# ---------------------------------------------------------------------
if [[ "$chatOrLink" =~ ^https?:// ]]; then
  # Treat as URL -> extract teamsChatId
  decodedLink=$(python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))" "$chatOrLink")
  teamsChatId=$(echo "$decodedLink" | grep -o '19:[^/]*@thread\.v2' | head -n 1)
  if [ -z "$teamsChatId" ]; then
    echo "Failed to extract teamsChatId from provided link."
    exit 1
  fi
  echo "Extracted teamsChatId from link: $teamsChatId"
else
  teamsChatId="$chatOrLink"
fi

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI (az) is not installed. Please install it first."
    exit 1
fi

# ---------------------------------------------------------------------
# Resolve tenantId (if not supplied) – Azure best-practice: use az context
# ---------------------------------------------------------------------
if [ -z "$tenantId" ]; then
  if ! command -v az &>/dev/null; then
    echo "Azure CLI (az) is not installed. Install it or pass tenantId."
    exit 1
  fi
  tenantId=$(az account show --query tenantId -o tsv 2>/dev/null)
  if [ -z "$tenantId" ]; then
    echo "Unable to determine tenantId from current az context."
    exit 1
  fi
  echo "Using tenantId: $tenantId"
fi

# Get the auth token
authToken=$(az account get-access-token --resource "https://teams.microsoft.com" --tenant "$tenantId" --query accessToken -o tsv)

if [ -z "$authToken" ]; then
    echo "Failed to retrieve Azure authentication token."
    exit 1
fi

# Make a POST call to get regionGtms/appService
authzUrl="https://teams.microsoft.com/api/authsvc/v1.0/authz"
authzResponse=$(curl -s -X POST "$authzUrl" --data '' \
    -H "Authorization: Bearer $authToken" \
    -H "Content-Type: application/json")

appService=$(echo "$authzResponse" | jq -r '.regionGtms.appService')

if [ -z "$appService" ] || [ "$appService" == "null" ]; then
    echo "Failed to extract regionGtms/appService from the response."
    exit 1
else
    echo "Extracted appService: $appService"
fi

# Iterate over all zip files in the directory
for zipFile in "$directory"/*.zip; do
    if [ -f "$zipFile" ]; then
        # Prepare the POST request
        url="$appService/beta/chats/$teamsChatId/apps/definitions/appPackage"
        headers=(
            -H "Authorization: Bearer $authToken"
            -H "Content-Type: application/x-zip-compressed"
        )

        # Perform the POST request
        curl "${headers[@]}" --data-binary @"$zipFile" "$url"
    else
        echo "No zip files found in the directory: $directory"
    fi
done