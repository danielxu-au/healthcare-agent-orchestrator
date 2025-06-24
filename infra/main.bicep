// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'resourceGroup'
// Common configurations
@description('Name of the environment')
param environmentName string
@description('Principal ID to grant access to the AI services. Leave empty to skip')
param myPrincipalId string = ''
@description('Current principal type being used')
@allowed(['User', 'ServicePrincipal'])
param myPrincipalType string
@description('Tags for all AI resources created. JSON object')
param tags object = {}

// AI Services configurations
@description('Name of the AI Services account. Automatically generated if left blank')
param aiServicesName string = ''
@description('Name of the AI Hub resource. Automatically generated if left blank')
param aiHubName string = ''
@description('Name of the Storage Account. Automatically generated if left blank')
param storageName string = ''
@description('Name of the Storage Account used by AppService for chat session data and patient data. Automatically generated if left blank')
param appStorageName string = ''
@description('Name of the Key Vault. Automatically generated if left blank')
param keyVaultName string = ''

// Other configurations
@description('Name of the Bot Service. Automatically generated if left blank')
param msiName string = ''
@description('Name of the App Service Plan. Automatically generated if left blank')
param appPlanName string = ''
@description('Name of the App Services Instance. Automatically generated if left blank')
param appName string = ''

@description('Gen AI model name and version to deploy')
@allowed(['gpt-4o;2024-11-20', 'gpt-4.1;2025-04-14'])
param model string
@description('Tokens per minute capacity for the model. Units of 1000 (capacity = 100 means 100K tokens per minute)')
param modelCapacity int
// https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/deployment-types
@description('Specify the deployment type of the model. Only allow deployment types where data processing and data storage is within the specified Azure geography.')
@allowed(['GlobalStandard','Standard', 'DataZoneStandard'])
param modelSku string

@description('Location to deploy AI Services')
param gptDeploymentLocation string = resourceGroup().location
@description('Location to deploy HLS models')
param hlsDeploymentLocation string = resourceGroup().location

@description('Instance type for HLS models')
param instanceType string = ''

@description('Deploy HLS models. Set to false to skip deployment of the expensive GPU resources.')
param deployHlsModels bool = true

@description('Location to deploy App Service')
param appServiceLocation string = resourceGroup().location
@description('Location to deploy Bot Service')
param botServiceLocation string = 'global'
@description('Location to deploy Healthcare Agent Service')
param healthcareAgentServiceLocation string = resourceGroup().location
@description('Location to deploy Key Vault')
param keyVaultLocation string = resourceGroup().location
@description('Location to deploy Managed Identity')
param msiLocation string = resourceGroup().location
param storageAccountLocation string = resourceGroup().location

@description('Alternative GPT model endpoint. This only affects the reasoning model')
param aiEndpointReasoningOverride string = ''
@description('Alternative GPT model deployment name for the reasoning model.')
param azureOpenaiDeploymentNameReasoningModelOverride string = ''

@description('Client ID for the Azure AD application used for authentication. Leave empty to skip')
param authClientId string = ''

@description('The scenario to use for the deployment.')
param scenario string = 'default'

@secure()
param graphRagSubscriptionKey string = ''

var modelName = split(model, ';')[0]
var modelVersion = split(model, ';')[1]

var abbrs = loadJsonContent('abbreviations.json')
var uniqueSuffix = substring(uniqueString(subscription().id, environmentName), 1, 3)
var location = resourceGroup().location

var names = {
  msi: !empty(msiName) ? msiName : '${abbrs.managedIdentityUserAssignedIdentities}${environmentName}-${uniqueSuffix}'
  appPlan: !empty(appPlanName) ? appPlanName : '${abbrs.webSitesAppServiceEnvironment}${environmentName}-${uniqueSuffix}'
  app: !empty(appName) ? appName : '${abbrs.webSitesAppService}${environmentName}-${uniqueSuffix}'
  aiServices: !empty(aiServicesName) ? aiServicesName : '${abbrs.cognitiveServicesAccounts}${environmentName}-${uniqueSuffix}'
  aiHub: !empty(aiHubName) ? aiHubName : '${abbrs.cognitiveServicesAccounts}hub-${environmentName}-${uniqueSuffix}'
  storage: !empty(storageName) ? storageName : replace(replace('${abbrs.storageStorageAccounts}${environmentName}${uniqueSuffix}', '-', ''), '_', '')
  appStorage: !empty(appStorageName) ? appStorageName : replace(replace('${abbrs.storageStorageAccounts}app${environmentName}${uniqueSuffix}', '-', ''), '_', '')
  keyVault: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}-${uniqueSuffix}'
}

var agentConfigs = {
  default: loadYamlContent('../src/scenarios/default/config/agents.yaml')
  // Add other scenarios here as needed
}

var allAgents = agentConfigs[scenario]

var agents = allAgents

var healthcareAgents = filter(allAgents, agent => contains(agent, 'healthcare_agent'))
var hasHealthcareAgentNeedingRadiologyModels = contains(map(healthcareAgents, agent => toLower(agent.name)), 'radiology')

module m_appServicePlan 'modules/appserviceplan.bicep' = {
  name: 'deploy_app_service_plan'
  params: {
    location: empty(appServiceLocation) ? location : appServiceLocation
    appServicePlanName: names.appPlan
    tags: tags
  }
}

module m_msi 'modules/msi.bicep' =[for i in agents:  {
  name: '${i.name}_deploy_msi'
  params: {
    location: empty(msiLocation) ? location : msiLocation
    msiName: i.name
    tags: tags
  }
  dependsOn: [
    // Ensure app service plan creation completes first to confirm quota availability.
    m_appServicePlan 
  ]
}]

// AI Services module
module m_aiservices 'modules/aistudio/aiservices.bicep' = {
  name: 'deploy_aiservices'
  params: {
    location: empty(gptDeploymentLocation) ? location : gptDeploymentLocation
    aiServicesName: names.aiServices
    grantAccessTo: [
          {
            id: myPrincipalId
            type: myPrincipalType
          }
        ]
    tags: tags
    additionalIdentities: [
      for i in range(0, length(agents)): m_msi[i].outputs.msiPrincipalID
    ]
  }
}

module m_keyVault 'modules/aistudio/keyVault.bicep' = {
  name: 'deploy_keyVault'
  params: {
    location: empty(keyVaultLocation) ? location : keyVaultLocation
    keyVaultName: names.keyVault
    grantAccessTo: [
        {
          id: myPrincipalId
          type: myPrincipalType
        }
      ]
    tags: tags
    additionalIdentities: [
      for i in range(0, length(agents)): m_msi[i].outputs.msiPrincipalID
    ]
  }
}

// AI Hub module - deploys AI Hub and Project
module m_aihub 'modules/aistudio/aihub.bicep' = {
  name: 'deploy_ai'
  params: {
    location: empty(hlsDeploymentLocation) ? location : hlsDeploymentLocation
    aiHubName: names.aiHub
    aiProjectName: 'cog-ai-prj-${environmentName}-${uniqueSuffix}'
    storageName: names.storage
    aiServicesName: m_aiservices.outputs.aiServicesName
    keyVaultName: m_keyVault.outputs.keyVaultName
    grantAccessTo:  [
          {
            id: myPrincipalId
            type: myPrincipalType
          }
        ]
    tags: tags
    additionalIdentities: [
      for i in range(0, length(agents)): m_msi[i].outputs.msiPrincipalID
    ]
  }
}

module hlsModels 'modules/hlsModel.bicep' = if (deployHlsModels) {
  name: 'deploy_hls_models'
  params: {
    location: empty(hlsDeploymentLocation) ? location : hlsDeploymentLocation
    workspaceName: 'cog-ai-prj-${environmentName}-${uniqueSuffix}'
    instanceType: instanceType
    includeRadiologyModels: empty(healthcareAgents) ? true : !hasHealthcareAgentNeedingRadiologyModels
  }
  dependsOn: [
    m_aihub
  ]
}

module m_gpt 'modules/gptDeployment.bicep' = {
  name: 'deploygpt'
  params: {
    aiServicesName: m_aiservices.outputs.aiServicesName
    modelName: modelName
    modelVersion: modelVersion
    modelCapacity: modelCapacity
    modelSku: modelSku
  }
}

module m_appStorageAccount 'modules/storageAccount.bicep' = {
  name: 'deploy_storage_account'
  params: {
    location: empty(storageAccountLocation) ? location : storageAccountLocation
    storageAccountName: names.appStorage
    grantAccessTo: [
      {
        id: myPrincipalId
        type: myPrincipalType
      }
      {
        id: m_msi[0].outputs.msiPrincipalID
        type: 'ServicePrincipal'
      }
    ]
    tags: tags
  }
}

module m_app 'modules/appservice.bicep' = {
  name: 'deploy_app'
  params: {
    location: empty(appServiceLocation) ? location : appServiceLocation
    appServicePlanId: m_appServicePlan.outputs.appServicePlanId
    appServiceName: names.app
    tags: tags
    deploymentName: m_gpt.outputs.modelName
    deploymentNameReasoningModel: empty(azureOpenaiDeploymentNameReasoningModelOverride) ? m_gpt.outputs.modelName : azureOpenaiDeploymentNameReasoningModelOverride
    openaiEnpoint: m_aiservices.outputs.aiServicesEndpoint
    openaiEndpointReasoningModel: empty(aiEndpointReasoningOverride) ? m_aiservices.outputs.aiServicesEndpoint : aiEndpointReasoningOverride
    aiProjectName: m_aihub.outputs.aiProjectName
    msis: [
      for i in range(0, length(agents)): {
        msiClientID: m_msi[i].outputs.msiClientID
        msiID: m_msi[i].outputs.msiID
        name: agents[i].name
      }
    ]
    modelEndpoints: deployHlsModels ? toObject(hlsModels.outputs.modelEndpoints, model => model.name, model => model.endpoint) : {}
    authClientId: authClientId
    appBlobStorageEndpoint: m_appStorageAccount.outputs.storageAccountBlobEndpoint
    graphRagSubscriptionKey: graphRagSubscriptionKey
    keyVaultName: m_keyVault.outputs.keyVaultName
    scenario: scenario
  }
}

module m_bot 'modules/botservice.bicep' = {
  name: 'deploy_bots'
  params: {
    location: empty(botServiceLocation) ? location : botServiceLocation
    tags: tags
    appBackend: m_app.outputs.backendHostName
    bots: [
      for i in range(0, length(agents)): {
        msiClientID: m_msi[i].outputs.msiClientID
        msiID: m_msi[i].outputs.msiID
        name: agents[i].name
      }
    ]
  }
}

module m_healthcareAgentService 'modules/healthcareAgentService.bicep' = if (!empty(healthcareAgents)) {
  name: 'deploy_healthcare_agents'
  params: {
    location: empty(healthcareAgentServiceLocation) ? location : healthcareAgentServiceLocation
    sku: 'F0'
    tags: tags
    bots: [
      for i in range(0, length(healthcareAgents)): {
        name: healthcareAgents[i].name
        msiID: m_msi[indexOf(map(allAgents, a => a.name), healthcareAgents[i].name)].outputs.msiID
      }
    ]
    keyVaultName: m_keyVault.outputs.keyVaultName
  }
}

output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP_ID string = resourceGroup().id
output AZURE_RESOURCE_GROUP_NAME string = resourceGroup().name
output AI_SERVICES_ENDPOINT string = m_aiservices.outputs.aiServicesEndpoint
output BACKEND_APP_HOSTNAME string = m_app.outputs.backendHostName
output MSI_PRINCIPAL_ID string = m_msi[0].outputs.msiPrincipalID
output AZURE_BOTS array = [for i in range(0, length(agents)): {name: agents[i].name, botId: m_msi[i].outputs.msiClientID}]
output BOT_IDS string = string(m_app.outputs.botIds)
output APP_STORAGE_ACCOUNT_NAME string = m_appStorageAccount.outputs.storageAccountName
output APP_BLOB_STORAGE_ENDPOINT string = m_appStorageAccount.outputs.storageAccountBlobEndpoint
output AZURE_OPENAI_API_ENDPOINT string = m_aiservices.outputs.aiServicesEndpoint
output AZURE_OPENAI_ENDPOINT string = m_aiservices.outputs.aiServicesEndpoint
output AZURE_OPENAI_DEPLOYMENT_NAME string = m_gpt.outputs.modelName
output AZURE_OPENAI_DEPLOYMENT_NAME_REASONING_MODEL string = m_gpt.outputs.modelName
output AZURE_OPENAI_REASONING_MODEL_ENDPOINT string = empty(aiEndpointReasoningOverride) ? m_aiservices.outputs.aiServicesEndpoint : aiEndpointReasoningOverride
output AZURE_AI_PROJECT_CONNECTION_STRING string = m_aihub.outputs.aiProjectConnectionString
output HLS_MODEL_ENDPOINTS string = string(m_app.outputs.modelEndpoints)
output KEYVAULT_ENDPOINT string = m_keyVault.outputs.keyVaultEndpoint
output HEALTHCARE_AGENT_SERVICE_ENDPOINTS array = !empty(healthcareAgents) ? m_healthcareAgentService.outputs.healthcareAgentServiceEndpoints : []
