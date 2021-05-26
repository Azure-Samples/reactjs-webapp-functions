param name_prefix string
param location string
param arcLocation string
param customLocationId string
param kubeEnvironmentId string

var webfarm_name = '${name_prefix}-webfarm-${uniqueString(resourceGroup().id)}'

resource webapi_farm_azure 'Microsoft.Web/serverfarms@2020-06-01' = if (customLocationId == '') {
  name: webfarm_name
  location: location
  kind: 'linux'
  sku: {
    name: 'P1V2'
  }
  properties: {
    reserved: true
  }
}

resource webapi_farm_arc 'Microsoft.Web/serverfarms@2020-12-01' = if (customLocationId != '') {
  name: concat(webfarm_name, 'arc')
  location: arcLocation
  kind: 'linux,kubernetes'
  sku: {
    name: 'K1'
    tier: 'Kubernetes'
    capacity: 1
  }
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    reserved: true
    perSiteScaling: true
    isXenon: false
    kubeEnvironmentProfile: {
      id: kubeEnvironmentId
    }
  }
}

output plan_id string = customLocationId == '' ? webapi_farm_azure.id : webapi_farm_arc.id
