// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string
param msiName string
param tags object = {}

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: msiName
  location: location
  tags: tags
}

output msiID string = msi.id
output msiName string = msi.name
output msiClientID string = msi.properties.clientId
output msiPrincipalID string = msi.properties.principalId
