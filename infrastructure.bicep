@description('The name of the function app that you wish to create.')
param appName string = 'ex-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var storageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'
var storageAccountType = 'Standard_LRS'
var StorageBlobDataReaderRoleID = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
var StorageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var StorageBlobDataOwnerRoleID = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var KeyVaultSecretsUserRoleID = '4633458b-17de-408a-b874-0445c86b69e6'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource storageAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource questionsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'questions'
  parent: storageAccountBlobService
  properties: {
    metadata: {}
    publicAccess: 'None'
  }
}

resource answersContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'answers'
  parent: storageAccountBlobService
  properties: {
    metadata: {}
    publicAccess: 'None'
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv${appName}'
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: false
    enableRbacAuthorization: true
    enabledForTemplateDeployment: true
  }
}

resource keyvaultReadingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'mi${appName}'
  location: location
}

resource functionsStorageAccountConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'functionsStorageAccountConnectionString-${storageAccountName}'
  parent: keyvault
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  dependsOn: [
    roleAssignmentStorageConnectionStringSecret
  ]
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${keyvaultReadingIdentity.id}': {}
    }
  }
  properties: {
    keyVaultReferenceIdentity: keyvaultReadingIdentity.id
    httpsOnly: true
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion:'Python|3.10' 
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: '@Microsoft.KeyVault(SecretUri=${functionsStorageAccountConnectionString.properties.secretUri})'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'blobTrigger_STORAGE' 
          value: '@Microsoft.KeyVault(SecretUri=${functionsStorageAccountConnectionString.properties.secretUri})'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: functionAppName
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'storageAccountName'
          value: storageAccountName
        }
        {
          name: 'questionsContainerName'
          value: questionsContainer.name
        }
        {
          name: 'answersContainerName'
          value: answersContainer.name
        }
      ]
    }
  }
}

//this is needed by Azure Functions to use Storage Account for Azure Functions needs
resource roleAssignmentStorageAccount 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, storageAccount.id, StorageBlobDataOwnerRoleID)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', StorageBlobDataOwnerRoleID)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

//this is needed by Azure Functions to read the storage account connection string
resource roleAssignmentStorageConnectionStringSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyvault.id, KeyVaultSecretsUserRoleID)
  scope: functionsStorageAccountConnectionString
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', KeyVaultSecretsUserRoleID)
    principalId: keyvaultReadingIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

//this is needed by blob trigger to read files in a particular container
resource roleAssignmentQuestionsContainer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, storageAccount.id, StorageBlobDataReaderRoleID)
  scope: questionsContainer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', StorageBlobDataReaderRoleID)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

//this is needed by blob trigger to write files to a particular container
resource roleAssignmentAnswersContainer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, storageAccount.id, StorageBlobDataContributorRoleID)
  scope: answersContainer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', StorageBlobDataContributorRoleID)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
