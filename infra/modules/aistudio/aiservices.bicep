// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string
param aiServicesName string
param tags object = {}
param grantAccessTo array
param additionalIdentities array = []

var access = [for i in range(0, length(additionalIdentities)): {
  id: additionalIdentities[i]
  type: 'ServicePrincipal'
}]

var grantAccessToUpdated = concat(grantAccessTo, access)

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'AIServices'
  properties: {
    disableLocalAuth: true
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow' 
    }
  }
  tags: tags
}

resource cognitiveServicesOpenAIContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'a001fd3d-188f-4b5d-821b-7da978bf7442'
}

resource cognitiveServicesUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'a97b65f3-24c7-4388-baec-2e87135dc908'
}

resource openaiAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principal in grantAccessToUpdated: if (!empty(principal.id)) {
    name: guid(principal.id, aiServices.id, cognitiveServicesOpenAIContributor.id)
    scope: aiServices
    properties: {
      roleDefinitionId: cognitiveServicesOpenAIContributor.id
      principalId: principal.id
      principalType: principal.type
    }
  }
]

resource userAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principal in grantAccessToUpdated: if (!empty(principal.id)) {
    name: guid(principal.id, aiServices.id, cognitiveServicesUser.id)
    scope: aiServices
    properties: {
      roleDefinitionId: cognitiveServicesUser.id
      principalId: principal.id
      principalType: principal.type
    }
  }
]

output aiServicesID string = aiServices.id
output aiServicesName string = aiServices.name
output aiServicesEndpoint string = aiServices.properties.endpoint
output aiServicesPrincipalId string = aiServices.identity.principalId
