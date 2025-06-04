// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

@description('Specifies the name of the Azure Storage account.')
param storageAccountName string

@description('Specifies the location in which the Azure Storage resources should be deployed.')
param location string

param tags object = {}
param grantAccessTo array = []

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowSharedKeyAccess: false
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: sa
  name: 'default'
}

resource chatArtifacts 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServices
  name: 'chat-artifacts'
}

resource chatSessions 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServices
  name: 'chat-sessions'
}

resource patientData 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServices
  name: 'patient-data'
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource blobWriterAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principal in grantAccessTo: if (!empty(principal.id)) {
    name: guid(principal.id, sa.id, storageBlobDataContributor.id)
    scope: sa
    properties: {
      roleDefinitionId: storageBlobDataContributor.id
      principalId: principal.id
      principalType: principal.type
    }
  }
]

output storageAccountID string = sa.id
output storageAccountName string = sa.name
output storageAccountBlobEndpoint string = sa.properties.primaryEndpoints.blob
