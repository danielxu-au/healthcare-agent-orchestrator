param (
    [string]$AZURE_TENANT_ID,
    [string]$ServiceManagementReference
)

$CLIENT_ID = $null
$AZURE_ENV_NAME = $null

$envValues = azd env get-values
$envValues.Split("`n") | ForEach-Object {
    $key, $value = $_.Split('=')
    $value = $value.Trim('"')
    if ($key -eq "CLIENT_ID") {
        $CLIENT_ID = $value
    }
    if ($key -eq "AZURE_ENV_NAME") {
        $AZURE_ENV_NAME = $value
    }
}

# If App Registration was not created, create it
if ($null -eq $CLIENT_ID) {
    Write-Host "Creating app registration..."
    $APP = (az ad app create --display-name $AZURE_ENV_NAME --enable-id-token-issuance --required-resource-accesses "@scripts/permissions.json" --service-management-reference $ServiceManagementReference) | ConvertFrom-Json
    $CLIENT_ID = $APP.appId
    azd env set CLIENT_ID $CLIENT_ID
}
else {
    Write-Host "App registration already exists. Skipping..."
}

