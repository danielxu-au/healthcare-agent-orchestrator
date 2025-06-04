# Install Azure CLI if not already installed
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Check if user is logged in
az account show
if ($LASTEXITCODE -ne 0) {
    return
}

$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$rootDirectory = Split-Path $scriptDirectory -Parent

# Define the path to your .env file
$envFilePath = "$rootDirectory\src\.env"

# Load the environment variables
Import-Csv $envFilePath -Delimiter '=' -Header Key,Value | ForEach-Object {
    [System.Environment]::SetEnvironmentVariable($_.Key, $_.Value)
}

# Define variables
$storageAccountName = $env:APP_STORAGE_ACCOUNT_NAME
$containerName = "patient-data"
$localFolderPath = "$rootDirectory\infra\patient_data"

# Upload files
Get-ChildItem -Path $localFolderPath | ForEach-Object {
    $path = $_.FullName
    $patientFolder = $path.Substring($localFolderPath.Length + 1).Replace("\", "/")

    if (Test-Path -Path $path -PathType Container) {
        Write-Output "Deleting patient data for $patientFolder"
        az storage blob delete-batch --account-name $storageAccountName --source $containerName --pattern "$patientFolder/*" --auth-mode login

        Write-Output "Uploading patient data from $path"
        az storage blob upload-batch --account-name $storageAccountName --destination "$containerName/$patientFolder" --source $path --auth-mode login --overwrite true
    }
}
