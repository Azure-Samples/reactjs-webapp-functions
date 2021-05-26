param location string
param arcLocation string
param name_prefix string
param workspace_id string
param plan_id string
param customLocationId string

param appSettings_pghost string
param appSettings_pguser string
@secure()
param appSettings_pgpassword string
param appSettings_pgdb string
param appSettings_node_env string
param appSettings_insights_key string
param appSettings_eventgridurl string

var webfarm_name = '${name_prefix}-webfarm'
var webapi_name = '${name_prefix}-webapi-${uniqueString(resourceGroup().id)}'

resource webapi 'Microsoft.Web/sites@2020-06-01' = if(customLocationId == '') {
  name: webapi_name
  location: location
  kind: ''
  properties: {
    siteConfig: {
      linuxFxVersion: 'NODE|14-lts'
      appSettings: [
        {
          name: 'PGHOST'
          value: '${appSettings_pghost}'
        }
        {
          name: 'PGUSER'
          value: '${appSettings_pguser}@${appSettings_pghost}'
        }
        {
          name: 'PGPASSWORD'
          value: '${appSettings_pgpassword}'
        }
        {
          name: 'PGDB'
          value: '${appSettings_pgdb}'
        }
        {
          name: 'NODE_ENV'
          value: '${appSettings_node_env}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '${appSettings_insights_key}'
        }
        {
          name: 'eventGridUrl'
          value: 'https://${appSettings_eventgridurl}'
        }
      ]
    }
    serverFarmId: plan_id
  }
}

resource diagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = if(customLocationId == '') {
  scope: webapi
  name: 'logAnalytics'
  properties: {
    workspaceId: workspace_id
    logs: [
      {
        enabled: true
        category: 'AppServicePlatformLogs'
      }
      {
        enabled: true
        category: 'AppServiceIPSecAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceFileAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceAppLogs'
      }
      {
        enabled: true
        category: 'AppServiceConsoleLogs'
      }
      {
        enabled: true
        category: 'AppServiceHTTPLogs'
      }
      {
        enabled: true
        category: 'AppServiceAntivirusScanAuditLogs'
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

resource webapiArc 'Microsoft.Web/sites@2020-12-01' = if(customLocationId != '') {
  name: concat(webapi_name, 'arc')
  location: arcLocation
  kind: 'linux,kubernetes,app'
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    siteConfig: {
      linuxFxVersion: 'NODE|14-lts'
      appSettings: [
        {
          name: 'PGHOST'
          value: '${appSettings_pghost}'
        }
        {
          name: 'PGUSER'
          value: '${appSettings_pguser}@${appSettings_pghost}'
        }
        {
          name: 'PGPASSWORD'
          value: '${appSettings_pgpassword}'
        }
        {
          name: 'PGDB'
          value: '${appSettings_pgdb}'
        }
        {
          name: 'NODE_ENV'
          value: '${appSettings_node_env}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '${appSettings_insights_key}'
        }
        {
          name: 'eventGridUrl'
          value: 'https://${appSettings_eventgridurl}'
        }
      ]
    }
    serverFarmId: plan_id
  }
}

resource diagnosticsArc 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = if(customLocationId != '') {
  scope: webapiArc
  name: 'logAnalytics'
  properties: {
    workspaceId: workspace_id
    logs: [
      {
        enabled: true
        category: 'AppServicePlatformLogs'
      }
      {
        enabled: true
        category: 'AppServiceIPSecAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceFileAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceAppLogs'
      }
      {
        enabled: true
        category: 'AppServiceConsoleLogs'
      }
      {
        enabled: true
        category: 'AppServiceHTTPLogs'
      }
      {
        enabled: true
        category: 'AppServiceAntivirusScanAuditLogs'
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

output webapi_id string = customLocationId == '' ? webapi.id : webapiArc.id
output webapi_hostname string = customLocationId == '' ? webapi.properties.hostNames[0] : webapiArc.properties.hostNames[0]
