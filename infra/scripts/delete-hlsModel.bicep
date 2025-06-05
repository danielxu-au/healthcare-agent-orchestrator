param workspaceName string = 'cog-ai-prj-auagents-6sb'
param location string = 'australiaeast'
param instanceType string = 'Standard_NC40ads_H100_v5'
param includeRadiologyModels bool = false // disables all models

module hlsModels '../modules/hlsModel.bicep' = {
  name: 'delete_hls_models'
  params: {
    workspaceName: workspaceName
    location: location
    instanceType: instanceType
    includeRadiologyModels: includeRadiologyModels // false = no models deployed
  }
}

// Usage:
// // To delete the HLS models in an Azure Machine Learning workspace, you can use the following command:
// az deployment group create --resource-group hlsagents --template-file infra/scripts/delete-hlsModel.bicep


// or 

// az ml online-endpoint delete \
//   --name <endpoint-name> \
//   --workspace-name <your-workspace> \
//   --resource-group <your-rg> \
//   --yes
