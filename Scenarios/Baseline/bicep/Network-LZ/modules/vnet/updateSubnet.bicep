param vnetName string
param subnetName string
param nsgId string
param rtId string
param sqlServiceep string= 'null'
param ehubServiceep string= 'null'
param kvServiceep string= 'null'

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: '${vnetName}/${subnetName}'
}

module updateNSG 'attachNsg.bicep' = {
  name: 'nsgupdate'
  params: {
    rtId: rtId
    vnetName: vnetName
    subnetName: subnetName
    nsgId: nsgId
    subnetAddressPrefix: subnet.properties.addressPrefix
    storageServiceep: 'Microsoft.Storage'
    sqlServiceep: sqlServiceep
    ehubServiceep: ehubServiceep
    kvServiceep: kvServiceep
  }
}

