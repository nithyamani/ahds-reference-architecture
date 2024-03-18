// Parameters
param publicipName string
param publicipsku object
param publicipproperties object
param location string = resourceGroup().location
param availabilityZones array

// Creating Public IP
resource publicip 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: publicipName
  location: location
  sku: publicipsku
  zones: !empty(availabilityZones) ? availabilityZones : null
  properties: publicipproperties
}

// Outputs
output publicipId string = publicip.id
output IpAddress string = publicip.properties.ipAddress
