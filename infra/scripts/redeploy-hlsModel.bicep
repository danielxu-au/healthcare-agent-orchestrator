param workspaceName string = 'cog-ai-prj-auagents-6sb'
param location string = 'australiaeast' 
param instanceType string = 'Standard_NC40ads_H100_v5'
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

//az deployment group create --resource-group hlsagents --template-file infra/scripts/redeploy-hlsModel.bicep --parameters workspaceName=cog-ai-prj-auagents-6sb location=australiaeast
