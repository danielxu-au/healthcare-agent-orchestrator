#!/bin/bash

# Install Azure CLI if not already installed
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli


if [ "$AZURE_PRINCIPAL_TYPE" == "ServicePrincipal" ]; then
    echo "Running as ServicePrincipal. Skipping uploading data."
    exit 0
fi

# Check if user is logged in
if ! az account show &>/dev/null; then
    echo "You are not logged in to Azure. Please log in and try again."
    exit 1
fi

# Define the script and root directories
scriptDirectory=$(dirname "$(realpath "$0")")
rootDirectory=$(dirname "$scriptDirectory")

# Define the path to your .env file
envFilePath="$rootDirectory/src/.env"

# Load the environment variables
if [ -f "$envFilePath" ]; then
    export $(grep -v '^#' "$envFilePath" | xargs)
else
    echo "Environment file not found at $envFilePath"
    exit 1
fi

# Define variables
storageAccountName="$APP_STORAGE_ACCOUNT_NAME"
containerName="patient-data"
localFolderPath="$rootDirectory/infra/patient_data"

# Upload files
for path in "$localFolderPath"/*; do
    if [ -d "$path" ]; then
        patientFolder=$(basename "$path")

        echo "Deleting patient data for $patientFolder"
        az storage blob delete-batch --account-name "$storageAccountName" --source "$containerName" --pattern "$patientFolder/*" --auth-mode login

        echo "Uploading patient data from $path"
        az storage blob upload-batch --account-name "$storageAccountName" --destination "$containerName/$patientFolder" --source "$path" --auth-mode login --overwrite true
    fi
done
