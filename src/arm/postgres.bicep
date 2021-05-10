param location string
param name_prefix string
param workspace_id string

param administratorLogin string = 'postgres_admin'
@secure()
param administratorLoginPassword string

var server_name = '${name_prefix}-postgres-${uniqueString(resourceGroup().id)}'

resource server 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: server_name
  location: location
  properties: {
    createMode: 'Default'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    sslEnforcement: 'Enabled'
  }
}

resource database 'Microsoft.DBForPostgreSQL/servers/databases@2017-12-01' = {
  name: '${server.name}/my_postgres'
}

resource firewall_rules 'Microsoft.DBForPostgreSQL/servers/firewallRules@2017-12-01' = {
  name: '${server.name}/AllowAny'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource diagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  scope: server
  name: 'logAnalytics'
    properties:{
    workspaceId: workspace_id
    logs:[
      {
        enabled: true
        category: 'PostgreSQLLogs'
      }
      {
        enabled: true
        category: 'QueryStoreRuntimeStatistics'
      }
      {
        enabled: true
        category: 'QueryStoreWaitStatistics'
      }
    ]
    metrics:[
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}

output pg_host string = server.properties.fullyQualifiedDomainName
output pg_user string = administratorLogin
output pg_password string = administratorLoginPassword
output pg_db string = last(split(database.name, '/'))
