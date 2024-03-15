param vnetName string
param subnetName string
param subnetAddressPrefix string
param nsgId string
param rtId string
param storageServiceep string= 'null'
param sqlServiceep string= 'null'
param ehubServiceep string= 'null'
param kvServiceep string= 'null'

var serviceEndpoints = []
var storageSEP = storageServiceep != 'null' ? concat(serviceEndpoints, [
  {
    service: storageServiceep
  }
] ) : serviceEndpoints
var sqlSEP = sqlServiceep != 'null' ? concat(storageSEP, [
  {
    service: sqlServiceep
  }
] ) : storageSEP
var eventHubSEP = ehubServiceep != 'null' ? concat(sqlSEP, [
  {
    service: ehubServiceep
  }
] ): sqlSEP
var kvSEP = kvServiceep != 'null' ? concat(eventHubSEP,  [
  {
    service: kvServiceep
  }
]) : eventHubSEP

resource nsgAttachment 'Microsoft.Network/virtualNetworks/subnets@2020-07-01' =  {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsgId
    }
    routeTable: {
      id: rtId
    }
    serviceEndpoints: kvSEP
  }
}
