param location string
param name_prefix string
param kubeEnvironment_id string
@secure()
param postgres_adminPassword string
@secure()
param teamsWebhookUrl string
param webapi_node_env string = 'production'

var is_kubeEnvironment = kubeEnvironment_id != null && kubeEnvironment_id != ''

module monitoring './monitoring.bicep' = {
  name: 'monitoring_deploy'
  params:{
    location: location
    name_prefix: name_prefix
    is_kubeEnvironment: is_kubeEnvironment
  }
}

module postgres './postgres.bicep' = {
  name: 'postgres_deploy'
  params:{
    location: location
    name_prefix: name_prefix
    workspace_id: monitoring.outputs.workspace_id
    administratorLoginPassword: postgres_adminPassword
  }
}

module plan './plan.bicep' = {
  name: 'plan_deploy'
  params:{
    location: location
    name_prefix: name_prefix
    kubeEnvironment_id: kubeEnvironment_id
    is_kubeEnvironment: is_kubeEnvironment
  }
}

module function './function.bicep' = {
  name: 'function_deploy'
  params:{
    location: location
    name_prefix: name_prefix
    workspace_id: monitoring.outputs.workspace_id
    appSettings_insights_key: monitoring.outputs.instrumentation_key
    is_kubeEnvironment: is_kubeEnvironment
    webapp_plan: plan.outputs.plan_id
    teamsWebhookUrl: teamsWebhookUrl
  }
}

module webapi './webapp.bicep' = {
  name: 'webapp_deploy'
  params:{
    location: location
    name_prefix: name_prefix
    plan_id: plan.outputs.plan_id
    is_kubeEnvironment: is_kubeEnvironment
    workspace_id: monitoring.outputs.workspace_id
    appSettings_pghost: postgres.outputs.pg_host
    appSettings_pguser: postgres.outputs.pg_user
    appSettings_pgdb: postgres.outputs.pg_db
    appSettings_node_env: webapi_node_env
    appSettings_pgpassword: postgres_adminPassword
    appSettings_insights_key: monitoring.outputs.instrumentation_key
    appSettings_eventgridurl: function.outputs.url
  }
}

output webapi_id string = webapi.outputs.webapi_id
output webapi_hostname string = webapi.outputs.webapi_hostname
output function_id string = function.outputs.function_id
output function_hostname string = function.outputs.function_hostname
output postgres_host string = postgres.outputs.pg_host
output postgres_user string = postgres.outputs.pg_user
output postgres_db string = postgres.outputs.pg_db
