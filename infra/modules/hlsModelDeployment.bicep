// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param workspaceName string
param instanceType string = 'Standard_NC40ads_H100_v5'
param modelId string
param location string
param name string

resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-10-01' existing = {
  name: workspaceName
}

resource modelEndpoint 'Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2024-10-01' = {
  parent: workspace
  location: location
  name: name
  properties: {
    authMode: 'AADToken'
    publicNetworkAccess: 'Enabled'
    traffic: {
      '${name}': 100
    }
  }

  identity: {
    type: 'SystemAssigned'
  }

  resource endpoint 'deployments' = {
    name: name
    location: location
    properties: {
      endpointComputeType: 'Managed'
      instanceType: instanceType
      model: modelId
      requestSettings: {
        requestTimeout: 'PT1M30S'
      }
      scaleSettings: {
        scaleType: 'Default'
      }
      livenessProbe: {
        initialDelay: 'PT10M'
      }
    }
    sku: {
      name: 'Default'
      tier: 'Standard'
      capacity: 1
    }
  }
}

output endpoint string = modelEndpoint.properties.scoringUri
