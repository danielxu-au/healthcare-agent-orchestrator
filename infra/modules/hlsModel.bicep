// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param workspaceName string
param location string
param instanceType string
param includeRadiologyModels bool = true

var actualInstanceType = instanceType == '' ? 'Standard_NC40ads_H100_v5' : instanceType

var models = includeRadiologyModels ? [
  {
    name: 'cxr_report_gen'
    modelId: 'azureml://registries/azureml/models/CxrReportGen/versions/6'
    instanceType: actualInstanceType
  }
] : []

var postfix = substring(uniqueString(resourceGroup().id), 1, 6)

module model_deploy 'hlsModelDeployment.bicep' = [for model in models: {
  name: 'deploy_${model.name}'
  params: {
    name: replace('${model.name}-${postfix}', '_', '-')
    workspaceName: workspaceName
    instanceType: model.instanceType
    modelId: model.modelId
    location: location
  }
}]

// Including this twice. First time we deploy the model. Second time we update the traffic to be 100%
// This is because we can't deploy and update the traffic in the same module
module model_update 'hlsModelDeployment.bicep' = [for model in models: {
  name: 'update_${model.name}'
  params: {
    name: replace('${model.name}-${postfix}', '_', '-')
    workspaceName: workspaceName
    instanceType: model.instanceType
    modelId: model.modelId
    location: location
  }
  dependsOn:[
    model_deploy
  ]
}]

output modelEndpoints array = [for (model, idx) in models: {
  name: model.name
  endpoint: model_deploy[idx].outputs.endpoint
}]
