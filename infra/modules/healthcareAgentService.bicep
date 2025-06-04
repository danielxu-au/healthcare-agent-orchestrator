// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string = 'eastus'
param sku string = 'F0'
param bots array = []
param tags object = {}
param keyVaultName string
@secure()
param secretValue string = ''

resource healthcareAgent 'Microsoft.HealthBot/healthBots@2024-02-01' = [
  for msi in bots: {
    identity: {
      type: 'UserAssigned'
      userAssignedIdentities: {
        '${msi.msiID}': {}
      }
    }
    name: toLower(msi.name)
    location: location
    tags: union({
      HealthcareAgentTemplate: 'MultiAgentCollaboration'
      AgentTemplate: '${msi.name}'
    }, tags)
    sku: {
      name: sku
    }
    properties: {}
  }
]

resource healthcareAgentKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// TODO: don't override secret value if already exists.
resource healthcareAgentKeyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [
  for msi in bots: {
    parent: healthcareAgentKeyVault
    name: 'HealthcareAgentService-${msi.name}-Secret'
    properties: {
      value: secretValue
      contentType: 'text/plain'
      attributes: {
        enabled: true
      }
    }
  }
]

output healthcareAgentServiceEndpoints array = [for (bot, idx) in bots: {
  id: healthcareAgent[idx].id
  name: bot.name
  managementPortalLink: healthcareAgent[idx].properties.botManagementPortalLink
  keyVaultSecretKey: healthcareAgentKeyVaultSecrets[idx].name
}]
