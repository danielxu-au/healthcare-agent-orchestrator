param workspaceName string
param location string
param instanceType string = ''
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
// az deployment group create \
//   --resource-group <your-rg> \
//   --template-file infra/scripts/delete-hlsModel.bicep \
//   --parameters workspaceName=<your-workspace> location=<location>


// or 

// az ml online-endpoint delete \
//   --name <endpoint-name> \
//   --workspace-name <your-workspace> \
//   --resource-group <your-rg> \
//   --yes
