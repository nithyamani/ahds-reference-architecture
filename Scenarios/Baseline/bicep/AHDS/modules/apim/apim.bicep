targetScope = 'resourceGroup'
// Parameters
@description('The name of the API Management resource to be created.')
param apimName string

@description('The subnet resource id to use for APIM.')
@minLength(1)
param apimSubnetId string

@description('The email address of the publisher of the APIM resource.')
@minLength(1)
param publisherEmail string = 'apim@jointcommission.org'

@description('Company name of the publisher of the APIM resource.')
@minLength(1)
param publisherName string = 'TJC'

@description('The pricing tier of the APIM resource.')
param apimSkuName string = 'Developer'

@description('The instance size of the APIM resource.')
param capacity int = 1

@description('Location for Azure resources.')
param location string = resourceGroup().location
param apimpip string

// Creating APIM Service
resource apimName_resource 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: location
  sku: {
    capacity: capacity
    name: apimSkuName
  }
  properties: {
    virtualNetworkType: 'Internal'
    natGatewayState: 'Disabled'
    publicIpAddressId: apimpip
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnetId
    }
  }
}

// Outputs
output apimName string = apimName_resource.name
