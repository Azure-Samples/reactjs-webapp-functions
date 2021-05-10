param location string
param name_prefix string

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  location : location
  name: '${name_prefix}-workspace'
}

resource insights 'Microsoft.Insights/components@2020-02-02-preview' = {
  location : location
  name: '${name_prefix}_insights_component'
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

output instrumentation_key string = insights.properties.InstrumentationKey
output workspace_id string = insights.properties.WorkspaceResourceId
