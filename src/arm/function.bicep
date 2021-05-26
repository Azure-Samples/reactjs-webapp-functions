param location string
param arcLocation string
param name_prefix string
param workspace_id string
param appSettings_insights_key string
param webapp_plan string
param teamsWebhookUrl string
param customLocationId string

var storage_name = '${uniqueString(resourceGroup().id)}stor'
var function_plan_name = '${name_prefix}-funcplan'
var function_name = '${name_prefix}-function-${uniqueString(resourceGroup().id)}'

resource storage_account 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storage_name
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource function 'Microsoft.Web/sites@2020-06-01' = if(customLocationId == '') {
  name: function_name
  location: location
  kind: 'functionapp,linux'
  properties: {
    siteConfig: {
      linuxFxVersion: 'Node|14'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_account.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage_account.id, storage_account.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_account.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage_account.id, storage_account.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '${appSettings_insights_key}'
        }
        {
          name: 'teamsWebhookUrl'
          value: '${teamsWebhookUrl}'
        }
      ]
    }
    serverFarmId: webapp_plan
    clientAffinityEnabled: false
  }
}

resource diagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = if(customLocationId == '') {
  scope: function
  name: 'logAnalytics'
  properties: {
    workspaceId: workspace_id
    logs: [
      {
        enabled: true
        category: 'FunctionAppLogs'
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}

resource functionArc 'Microsoft.Web/sites@2020-12-01' = if(customLocationId != '') {
  name: concat(function_name, 'arc')
  location: arcLocation
  kind: 'kubernetes,functionapp,linux'
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    siteConfig: {
      linuxFxVersion: 'Node|14'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_account.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage_account.id, storage_account.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_account.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage_account.id, storage_account.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '${appSettings_insights_key}'
        }
        {
          name: 'teamsWebhookUrl'
          value: '${teamsWebhookUrl}'
        }
      ]
    }
    serverFarmId: webapp_plan
    clientAffinityEnabled: false
  }
}

resource diagnosticsArc 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = if(customLocationId != '') {
  scope: functionArc
  name: 'logAnalytics'
  properties: {
    workspaceId: workspace_id
    logs: [
      {
        enabled: true
        category: 'FunctionAppLogs'
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}

output function_id string = customLocationId == '' ? function.id : functionArc.id
output function_hostname string = customLocationId == '' ? function.properties.hostNames[0] : functionArc.properties.hostNames[0]
output url string = customLocationId == '' ? '${function.properties.hostNames[0]}/api/EventGridHttpTrigger' : '${functionArc.properties.hostNames[0]}/api/EventGridHttpTrigger'
