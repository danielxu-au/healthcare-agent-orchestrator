param workspaceName string
param location string
param instanceType string = ''
param includeRadiologyModels bool = true

module hlsModels '../modules/hlsModel.bicep' = {
  name: 'redeploy_hls_models'
  params: {
    workspaceName: workspaceName
    location: location
    instanceType: instanceType
    includeRadiologyModels: includeRadiologyModels
  }
}


// Usage:// To redeploy the HLS models in an Azure Machine Learning workspace, you can use the following command:
// Make sure to replace <your-rg>, <your-workspace>, and <location> with your actual resource group name, workspace name, and Azure region.

//az deployment group create \
//  --resource-group <your-rg> \
//  --template-file infra/scripts/redeploy-hlsModel.bicep \
//  --parameters workspaceName=<your-workspace> location=<location>
