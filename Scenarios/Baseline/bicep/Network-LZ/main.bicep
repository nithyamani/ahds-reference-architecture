targetScope = 'subscription'

// Parameters
param fhirRGName string
param apimRGName string
param vnetRGName string
param vnetSpokeName string
param rtFHIRSubnetName string
param nsgFHIRName string
param nsgAppGWName string
param nsgAPIMName string
param rtAppGWSubnetName string
param location string = deployment().location
param appGatewaySubnetName string
param FHIRSubnetName string
param APIMSubnetName string

// Creating Resource Group
module fhirRG 'modules/resource-group/rg.bicep' = {
  name: fhirRGName
  params: {
    rgName: fhirRGName
    location: location
  }
}

// Creating NSG for FHIR Subnet
module nsgfhirsubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(fhirRG.name)
  name: nsgFHIRName
  params: {
    location: location
    nsgName: nsgFHIRName
  }
}

// Creating FHIR route table
module routetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(fhirRG.name)
  name: rtFHIRSubnetName
  params: {
    location: location
    rtName: rtFHIRSubnetName
  }
}

// Defining Virtual Network
resource vnetspoke 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  scope: resourceGroup(vnetRGName)
  name: vnetSpokeName
}

// Creating Private DNS Zone for Key Vault
module privatednsVaultZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsVaultZone'
  params: {
    privateDNSZoneName: 'privatelink.vaultcore.azure.net'
  }
}

// Linking Private DNS Zone for Key Vault to Spoke VNet (required for AppGW to work properly to load Cert from a Private Endpoing Key Vault)
module privateDNSLinkVaultSpoke 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privateDNSLinkVaultSpoke'
  params: {
    privateDnsZoneName: privatednsVaultZone.outputs.privateDNSZoneName
    vnetId: vnetspoke.id
    linkName: 'link-spoke'
  }
}

// APIM DNS Zones
// Creating Private DNS Zone for APIM
module privatednsazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsazureapinet'
  params: {
    privateDNSZoneName: 'azure-api.net'
  }
}

// Linking Private DNS Zone for APIM to VNet
module privatednsazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsazureapinetLink'
  params: {
    privateDnsZoneName: privatednsazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.id
  }
}

// Creating Private DNS Zone for APIM portal
module privatednsportalazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsportalazureapinet'
  params: {
    privateDNSZoneName: 'portal.azure-api.net'
  }
}

// Linking Private DNS Zone for APIM portal to VNet
module privatednsportalazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsportalazureapinetLink'
  params: {
    privateDnsZoneName: privatednsportalazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.id
  }
}

// Creating Private DNS Zone for APIM developer
module privatednsdeveloperazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsdeveloperazureapinet'
  params: {
    privateDNSZoneName: 'developer.azure-api.net'
  }
}

// Linking Private DNS Zone for APIM developer to VNet
module privatednsdeveloperazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsdeveloperazureapinetLink'
  params: {
    privateDnsZoneName: privatednsdeveloperazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.id
  }
}

// Creating Private DNS Zone for APIM management
module privatednsmanagementazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsmanagementazureapinet'
  params: {
    privateDNSZoneName: 'management.azure-api.net'
  }
}

// Linking Private DNS Zone for APIM management to VNet
module privatednsmanagementazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsmanagementazureapinetLink'
  params: {
    privateDnsZoneName: privatednsmanagementazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.id
  }
}

// Creating Private DNS Zone for APIM scm
module privatednsscmazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsscmazureapinet'
  params: {
    privateDNSZoneName: 'scm.azure-api.net'
  }
}

// Linking Private DNS Zone for APIM scm to VNet
module privatednsscmazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(apimRGName)
  name: 'privatednsscmazureapinetLink'
  params: {
    privateDnsZoneName: privatednsscmazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.id
  }
}

// FHIR DNZ Zones
// Creating Private DNS Zone for FHIR
module privatednsfhir 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(fhirRG.name)
  name: 'privatednsfhir'
  params: {
    privateDNSZoneName: 'privatelink.azurehealthcareapis.com'
  }
}

// Linking Private DNS Zone for FHIR to VNet
module privatednsfhirLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(fhirRG.name)
  name: 'privatednsfhirLink'
  params: {
    privateDnsZoneName: privatednsfhir.outputs.privateDNSZoneName
    vnetId: vnetspoke.id
  }
}

// Creating NSG for AppGW Subnet
module nsgappgwsubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(apimRGName)
  name: nsgAppGWName
  params: {
    location: location
    nsgName: nsgAppGWName
    securityRules: [
      {
        name: 'Allow443InBound'
        properties: {
          priority: 102
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowControlPlaneV1SKU'
        properties: {
          priority: 110
          sourceAddressPrefix: 'GatewayManager'
          protocol: '*'
          destinationPortRange: '65503-65534'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowControlPlaneV2SKU'
        properties: {
          priority: 111
          sourceAddressPrefix: 'GatewayManager'
          protocol: '*'
          destinationPortRange: '65200-65535'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHealthProbes'
        properties: {
          priority: 120
          sourceAddressPrefix: 'AzureLoadBalancer'
          protocol: '*'
          destinationPortRange: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Creating NSG for APIM Subnet
module nsgapimsubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(apimRGName)
  name: nsgAPIMName
  params: {
    location: location
    nsgName: nsgAPIMName
    securityRules: [
      {
        name: 'AllowApiManagement'
        properties: {
          priority: 120
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowStorage'
        properties: {
          priority: 100
          sourceAddressPrefix: '*'
          protocol: '*'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowSQL'
        properties: {
          priority: 140
          sourceAddressPrefix: '*'
          protocol: '*'
          destinationPortRange: '1433'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          priority: 130
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '6390'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowAzureKeyVault'
        properties: {
          priority: 110
          sourceAddressPrefix: '*'
          protocol: '*'
          destinationPortRanges: ['443']
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Creating AppGW Route Table
module appgwroutetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(apimRGName)
  name: rtAppGWSubnetName
  params: {
    location: location
    rtName: rtAppGWSubnetName
  }
}

module updateappgwNSG 'modules/vnet/updateSubnet.bicep' = {
  scope: resourceGroup(vnetRGName)
  name: 'AppGWSubnetNamensgupdate'
  params: {
    rtId: appgwroutetable.outputs.routetableID
    vnetName: vnetSpokeName
    subnetName: appGatewaySubnetName
    nsgId: nsgappgwsubnet.outputs.nsgID  
  }
  dependsOn: [
    vnetspoke
    nsgappgwsubnet
    updateApimNSG
  ]
}

module updateApimNSG 'modules/vnet/updateSubnet.bicep' = {
  scope: resourceGroup(vnetRGName)
  name: 'APIMSubnetNamensgupdate'
  params: {
    rtId: routetable.outputs.routetableID
    vnetName: vnetSpokeName
    subnetName: APIMSubnetName
    nsgId: nsgapimsubnet.outputs.nsgID   
    sqlServiceep: 'Microsoft.Sql'
    ehubServiceep: 'Microsoft.EventHub'
    kvServiceep: 'Microsoft.KeyVault' 
  }
  dependsOn: [
    vnetspoke
    nsgapimsubnet
  ]
}

module updatefhirNSG 'modules/vnet/updateSubnet.bicep' = {
  scope: resourceGroup(vnetRGName)
  name: 'FhirSubnetNamensgupdate'
  params: {
    rtId: routetable.outputs.routetableID
    vnetName: vnetSpokeName
    subnetName: FHIRSubnetName
    nsgId: nsgfhirsubnet.outputs.nsgID      
  }
  dependsOn: [
    vnetspoke
    updateappgwNSG
    nsgfhirsubnet
  ]
}
