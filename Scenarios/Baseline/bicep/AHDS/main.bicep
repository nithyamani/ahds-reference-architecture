targetScope = 'subscription'

// Parameters
param apimRGName string
param fhirRGName string
param vnetRGName string
param keyVaultPrivateEndpointName string
param vnetName string
param subnetName string
param APIMsubnetName string
param APIMNamePrefix string
param KeyVaultNamePrefix string
param APIMName string = '${APIMNamePrefix}-${uniqueString('acrvws', utcNow('u'))}'
param privateDNSZoneKVName string
param privateDNSZoneFHIRName string
param keyvaultName string = '${KeyVaultNamePrefix}-${uniqueString('acrvws', utcNow('u'))}'
param location string = deployment().location
param appGatewayName string
param appGatewaySubnetName string
param availabilityZones array
param appGwyAutoScale object
param appGatewayFQDN string
@description('Set to selfsigned if self signed certificates should be used for the Application Gateway. Set to custom and copy the pfx file to vnet/certs/appgw.pfx if custom certificates are to be used')
param appGatewayCertType string
@secure()
param certPassword string

param fhirName string
param FhirWorkspaceNamePrefix string
param workspaceName string = '${FhirWorkspaceNamePrefix}${uniqueString('workspacevws', utcNow('u'))}'
param ApiUrlPath string
param apimpipdnsname string = 'ent-dev-apim-pip-${uniqueString('apimpipdns', utcNow('u'))}'
param keyVaultsku string
param apimSkuName string
param apimPublisherEmail string
param apimPublisherName string
param appgwSku string
var primaryBackendEndFQDN = '${APIMName}.azure-api.net'

// Defining Resource Group
resource apimRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: apimRGName
}

// Defining Private Endpoint Subnet
resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(vnetRGName)
  name: '${vnetName}/${subnetName}'
}

// Creating Key Vault
module keyvault 'modules/keyvault/keyvault.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: keyvaultName
  params: {
    location: location
    keyVaultsku: keyVaultsku
    name: keyvaultName
    tenantId: subscription().tenantId
    networkAction: 'Deny'
  }
}

// Creating Private Endpoint Key Vault
module privateEndpointKeyVault 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: keyVaultPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'Vault'
    ]
    privateEndpointName: keyVaultPrivateEndpointName
    privatelinkConnName: '${keyVaultPrivateEndpointName}-conn'
    resourceId: keyvault.outputs.keyvaultId
    subnetid: servicesSubnet.id
  }
}

// Defining Key Vault Private DNS Zone
resource privateDNSZoneKV 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(apimRG.name)
  name: privateDNSZoneKVName
}

// Creating Key Vault Private DNS Settings for Private DNS Zone
module privateEndpointKVDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: 'kv-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneKV.id
    privateEndpointName: privateEndpointKeyVault.name
  }
}

// Defining APIM Subnet
resource APIMSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(vnetRGName)
  name: '${vnetName}/${APIMsubnetName}'
}

// Create Public IP for APIM
module publicipapim 'modules/vnet/publicip.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: 'ent-dev-apim-pip'
  params: {
    availabilityZones: availabilityZones
    location: location
    publicipName: 'ent-dev-apim-pip'
    publicipproperties: {
      publicIPAllocationMethod: 'Static'
      publicIPAddressVersion: 'IPv4'
      dnsSettings: {
        domainNameLabel: apimpipdnsname
      }
    }
    publicipsku: {
      name: 'Standard'
      tier: 'Regional'
    }
  }
}

// Creating APIM
module apimModule 'modules/apim/apim.bicep' = {
  name: 'apimDeploy'
  scope: resourceGroup(apimRG.name)
  params: {
    apimName: APIMName
    apimSubnetId: APIMSubnet.id
    location: location
    apimpip: publicipapim.outputs.publicipId
    apimSkuName: apimSkuName
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
  }
}

// Adding APIM DNS Records
module apimDNSRecords 'modules/vnet/apimprivatednsrecords.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: 'apimDNSRecords'
  params: {
    RG: apimRG.name
    apimName: apimModule.outputs.apimName
  }
}

// Create Public IP for Application Gateway
module publicipappgw 'modules/vnet/publicip.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: 'ent-dev-appgw-pip'
  params: {
    availabilityZones: availabilityZones
    location: location
    publicipName: 'ent-dev-appgw-pip'
    publicipproperties: {
      publicIPAllocationMethod: 'Static'
    }
    publicipsku: {
      name: 'Standard'
      tier: 'Regional'
    }
  }
}

// Defining Application Gateway Subnet
resource appgwSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(vnetRGName)
  name: '${vnetName}/${appGatewaySubnetName}'
}

// Creating Application Gateway Identity (used for AppGW access Key Vault to load Certificate)
module appgwIdentity 'modules/Identity/userassigned.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: 'appgwIdentity'
  params: {
    location: location
    identityName: 'appgwIdentity'
  }
}

// Giving Access to Key Vault for Application Gateway Identity to read Keys, Secrets, Certificates
module kvrole 'modules/Identity/kvrole.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: 'kvrole'
  params: {
    principalId: appgwIdentity.outputs.azidentity.properties.principalId
    roleGuid: 'f25e0fa2-a7c8-4377-a976-54943a77a395' //Key Vault Contributor
    keyvaultName: keyvaultName
  }
}

// Generating/Loading certificate to Azure Key Vault (Depending in the parameters it can load or generete a new Self-Signed certificate)
module certificate 'modules/vnet/certificate.bicep' = {
  name: 'certificate'
  scope: resourceGroup(apimRG.name)
  params: {
    managedIdentity: appgwIdentity.outputs.azidentity
    keyVaultName: keyvaultName
    location: location
    appGatewayFQDN: appGatewayFQDN
    appGatewayCertType: appGatewayCertType
    certPassword: certPassword
    rgName: apimRG.name
  }
  dependsOn: [
    kvrole
  ]
}

// Creating Application Gateway (This resource will only be created after APIM API Import finishes)
module appgw 'modules/vnet/appgw.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: 'appgw'
  params: {
    appGwyAutoScale: appGwyAutoScale
    availabilityZones: availabilityZones
    location: location
    appgwname: appGatewayName
    appgwpip: publicipappgw.outputs.publicipId
    subnetid: appgwSubnet.id
    appGatewayIdentityId: appgwIdentity.outputs.identityid
    appGatewayFQDN: appGatewayFQDN
    keyVaultSecretId: certificate.outputs.secretUri
    primaryBackendEndFQDN: primaryBackendEndFQDN
    appgwSku: appgwSku
  }
  dependsOn: [
   apimImportAPI
  ]
}

// Create FHIR service
// Giving Access to AppGW Identity to APIM, since we are re-using the same MI to load the APIM FHIR API at APIM
module apimrole 'modules/Identity/apimrole.bicep' = {
  scope: resourceGroup(apimRG.name)
  name: 'apimrole'
  params: {
    principalId: appgwIdentity.outputs.azidentity.properties.principalId
    roleGuid: '312a565d-c81f-4fd8-895a-4e21e48d571c' //APIM Contributor
    apimName: apimModule.outputs.apimName
  }
}

// Creating FHIR Service
module fhir 'modules/ahds/fhirservice.bicep' = {
  scope: resourceGroup(fhirRGName)
  name: fhirName
  params: {
    fhirName: fhirName
    workspaceName: workspaceName
  }
}

// Creating FHIR Private Endpoint
module privateEndpointFHIR 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(fhirRGName)
  name: 'fhir-pvtep'
  params: {
    location: location
    groupIds: [
      'healthcareworkspace'
    ]
    privateEndpointName: 'fhir-pvtep'
    privatelinkConnName: 'fhir-pvtep-conn'
    resourceId: fhir.outputs.fhirWorkspaceID
    subnetid: servicesSubnet.id
  }
}

// Defining FHIR Private DNS Zone for FHIR
resource privateDNSZoneFHIR 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(fhirRGName)
  name: privateDNSZoneFHIRName
}

// Creating Private DNS Setting for FHIR Private DNS Settings
module privateEndpointFHIRDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(fhirRGName)
  name: 'fhir-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneFHIR.id
    privateEndpointName: privateEndpointFHIR.name
  }
}

// Importing FHIR at APIM (This is using deployment script, it will load the Swagger API definition from GitHub)
module apimImportAPI 'modules/apim/api-deploymentScript.bicep' = {
  name: 'apimImportAPI'
  scope: resourceGroup(apimRG.name)
  params: {
    managedIdentity: appgwIdentity.outputs.azidentity
    location: location
    RGName: apimRG.name
    APIMName: apimModule.outputs.apimName
    serviceUrl: fhir.outputs.serviceHost
    APIFormat: 'Swagger'
    APIpath: 'fhir'
    ApiUrlPath: ApiUrlPath
  }
  dependsOn: [
    apimrole
  ]
}

// Outputs
output keyvaultName string = keyvault.name
output publicipappgw string = publicipappgw.outputs.IpAddress
output publicipapim string = publicipapim.outputs.IpAddress
