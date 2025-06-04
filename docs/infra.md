# Infrastructure

## Authentication

To enable secure file downloads, we support single sign-on (SSO) through our app for authentication.
We first need to create an App ID to support authentication.
This step is optional and can be skipped if you don't need authentication (for example, if you are testing with public data).
Create the app using the following command:
```ps
.\scripts\createAppId.ps1 -AZURE_TENANT_ID <TENANT> -ServiceManagementReference <metadata>
```
The tenant ID can be obtained by going to https://entra.microsoft.com in the Overview section.

Once this step has been completed, run the following command to configure the backend with authentication enabled:
```
azd up
```

## Regional Availability

You need to deploy AZURE_GPT_LOCATION in a region where Azure AI agents support the model:
https://learn.microsoft.com/en-us/azure/ai-services/agents/concepts/model-region-support?tabs=python

You can control where the GPT model, the HLS model, and the App Service Plan are deployed. For example:
```sh
# For example:
azd env set AZURE_HLS_LOCATION eastus2
azd env set AZURE_GPT_LOCATION westus3
azd env set AZURE_APPSERVICE_LOCATION canadacentral
azd env set AI_ENDPOINT_REASONING_OVERRIDE <open-ai reasoning model endpoint>
azd env set AZURE_OPENAI_DEPLOYMENT_NAME_REASONING_MODEL_OVERRIDE <openai reasoning model deployment name>
```

Review `./infra/main.parameters.json` for a full list of available environment configurations.

## Security

All resources within this template use Entra ID authentication. No passwords are stored in the infrastructure.

> [!WARNING]
> Be advised that the web app does expose a public unauthenticated endpoint (unless you have enabled authentication) and that the files you put under infra/patient_data will be publicly available.
