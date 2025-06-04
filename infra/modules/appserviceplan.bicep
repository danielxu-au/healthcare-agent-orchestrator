// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string
param appServicePlanName string
param sku string = 'P1mv3'
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: 1
  }
  properties: {
    reserved: true
  }
  kind: 'linux'
}

output appServicePlanId string = appServicePlan.id
