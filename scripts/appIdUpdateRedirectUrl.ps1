
$AZURE_TENANT_ID = azd env get-value AZURE_TENANT_ID
$BACKEND_APP_HOSTNAME = azd env get-value BACKEND_APP_HOSTNAME
$APP_REGISTRATION_DONE = $null
$CLIENT_ID = $null

$envValues = azd env get-values
$envValues.Split("`n") | ForEach-Object {
    $key, $value = $_.Split('=')
    $value = $value.Trim('"')
    if ($key -eq "APP_REGISTRATION_DONE") {
        $APP_REGISTRATION_DONE = $value
    }
    if ($key -eq "CLIENT_ID") {
        $CLIENT_ID = $value
    }
}

if ($null -eq $CLIENT_ID) {
    Write-Host "CLIENT_ID is null. Exiting script."
    exit
}

if ($null -ne $APP_REGISTRATION_DONE) {
    Write-Host "APP_REGISTRATION_DONE is set. Not doing it a second time."
    exit
}

az ad app update --id $CLIENT_ID --web-redirect-uris "https://$BACKEND_APP_HOSTNAME/.auth/login/aad/callback" "https://token.botframework.com/.auth/web/redirect" 

# If a federated identity doesn't exist, create it
$uuid_no_hyphens = $AZURE_TENANT_ID -replace "-", ""
$uuid_reordered = $uuid_no_hyphens.Substring(6, 2) + $uuid_no_hyphens.Substring(4, 2) + $uuid_no_hyphens.Substring(2, 2) + $uuid_no_hyphens.Substring(0, 2) +
$uuid_no_hyphens.Substring(10, 2) + $uuid_no_hyphens.Substring(8, 2) +
$uuid_no_hyphens.Substring(14, 2) + $uuid_no_hyphens.Substring(12, 2) +
$uuid_no_hyphens.Substring(16, 16)
$uuid_binary = [System.Convert]::FromHexString($uuid_reordered)
$B64_AZURE_TENANT_ID = [Convert]::ToBase64String($uuid_binary) -replace '\+', '-' -replace '/', '_' -replace '=', ''

echo "{
        `"audiences`": [`"api://AzureADTokenExchange`"],
        `"description`": `"`",
        `"issuer`": `"https://login.microsoftonline.com/$AZURE_TENANT_ID/v2.0`",
        `"name`": `"default`",
        `"subject`": `"/eid1/c/pub/t/$B64_AZURE_TENANT_ID/a/9ExAW52n_ky4ZiS_jhpJIQ/$CLIENT_ID`"
    }" | Out-File tmp.json

Write-Host "Creating federated identity..."
az ad app federated-credential create --id $CLIENT_ID --parameters tmp.json | Out-Null

rm tmp.json
azd env set APP_REGISTRATION_DONE true