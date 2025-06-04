// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string

// Dependencies
param aiServicesName string
param keyVaultName string

// Azure AI configuration
param aiHubName string
param aiProjectName string
param storageName string
// Other
param tags object = {}
param grantAccessTo array
param defaultComputeName string = ''
param additionalIdentities array = []

var access = [for i in range(0, length(additionalIdentities)): {
  id: additionalIdentities[i]
  type: 'ServicePrincipal'
}]

var grantAccessToUpdated = concat(grantAccessTo, access)

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiServicesName
}
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isLocalUserEnabled: false
    allowSharedKeyAccess: false
    accessTier: 'Hot'
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: replace('${aiHubName}-registry', '-', '')
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}


resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: aiHubName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    friendlyName: aiHubName
    keyVault: keyVault.id
    storageAccount: storage.id
    systemDatastoresAuthMode: 'identity'
    containerRegistry: acrResource.id
  }
  kind: 'hub'

  resource aiServicesConnection 'connections@2024-04-01' = {
    name: '${aiHubName}-connection-AIServices'
    properties: {
      category: 'AIServices'
      target: aiServices.properties.endpoint
      authType: 'AAD'
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServices.id
        ApiVersion: '2023-07-01-preview'
        DeploymentApiVersion: '2023-10-01-preview'
        Location: location
      }
    }
  }

  resource defaultCompute 'computes@2024-04-01-preview' = if (!empty(defaultComputeName)) {
    name: defaultComputeName
    location: location
    tags: tags
    properties: {
      computeType: 'ComputeInstance'
      properties: {
        vmSize: 'Standard_DS11_v2'
      }
    }
  }
}

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: aiProjectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    hubResourceId: aiHub.id
  }
  kind: 'Project'
}

resource aiDeveloper 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '64702f94-c441-49e6-a78b-ef80e0188fee'
}

resource aiDeveloperAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principal in grantAccessToUpdated: if (!empty(principal.id)) {
    name: guid(principal.id, aiHub.id, aiDeveloper.id)
    scope: aiHub
    properties: {
      roleDefinitionId: aiDeveloper.id
      principalId: principal.id
      principalType: principal.type
    }
  }
]

resource aiDeveloperAccessProj 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principal in grantAccessToUpdated: if (!empty(principal.id)) {
    name: guid(principal.id, aiProject.id, aiDeveloper.id)
    scope: aiProject
    properties: {
      roleDefinitionId: aiDeveloper.id
      principalId: principal.id
      principalType: principal.type
    }
  }
]

resource cognitiveServicesOpenAIContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'a001fd3d-188f-4b5d-821b-7da978bf7442'
}

resource openaiAccessFromProject 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(aiProject.id, aiServices.id, cognitiveServicesOpenAIContributor.id)
    scope: aiServices
    properties: {
      roleDefinitionId: cognitiveServicesOpenAIContributor.id
      principalId: aiProject.identity.principalId
      principalType: 'ServicePrincipal'
    }
}


output aiHubID string = aiHub.id
output aiHubName string = aiHub.name
output aiProjectID string = aiProject.id
output aiProjectName string = aiProject.name
output aiProjectDiscoveryUrl string = aiProject.properties.discoveryUrl
output aiProjectConnectionString string = '${split(aiProject.properties.discoveryUrl, '/')[2]};${subscription().subscriptionId};${resourceGroup().name};${aiProject.name}'
