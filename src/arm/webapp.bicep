param location string
param name_prefix string
param workspace_id string
param plan_id string
param is_kubeEnvironment bool

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

resource webapi 'Microsoft.Web/sites@2020-06-01' = {
  name: webapi_name
  location: location
  kind: !is_kubeEnvironment ? '' : 'kubeapp'
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
          value: !is_kubeEnvironment ? 'https://${appSettings_eventgridurl}' : 'http://${appSettings_eventgridurl}'
        }
      ]
    }
    serverFarmId: plan_id
  }
}

resource diagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
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

output webapi_id string = webapi.id
output webapi_hostname string = webapi.properties.hostNames[0]
