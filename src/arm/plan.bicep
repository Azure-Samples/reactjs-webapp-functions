param name_prefix string
param location string
param is_kubeEnvironment bool = false
param kubeEnvironment_id string

var webfarm_name = '${name_prefix}-webfarm-${uniqueString(resourceGroup().id)}'

resource webapi_farm_azure 'Microsoft.Web/serverfarms@2020-06-01' = if (!is_kubeEnvironment) {
  name: concat(webfarm_name, '-azure')
  location: location
  kind: 'linux'
  sku: {
    name: 'P1V2'
  }
  properties: {
    reserved: true
  }
}

resource webapi_farm_arc 'Microsoft.Web/serverfarms@2020-06-01' = if (is_kubeEnvironment) {
  name: concat(webfarm_name, '-arc')
  location: location
  kind: 'K8SE'
  sku: {
    name: 'B1'
    tier: 'ANY'
  }
  properties: {
    kubeEnvironmentProfile: {
      id: kubeEnvironment_id
    }
  }
}

output plan_id string = !is_kubeEnvironment ? webapi_farm_azure.id : webapi_farm_arc.id
