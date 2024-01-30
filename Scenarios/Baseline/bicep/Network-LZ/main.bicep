targetScope = 'subscription'

// Parameters
param rgName string
param vnetSpokeName string
param rtFHIRSubnetName string
param nsgFHIRName string
param nsgAppGWName string
param rtAppGWSubnetName string
param location string = deployment().location
param resourceSuffix string
param appGatewaySubnetName string
param FHIRSubnetName string
param spokeVNETaddPrefixes array

param spokeSubnets array

// Creating Resource Group
module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

// Creating Log Analytics Workspace
module monitor 'modules/azmon/azmon.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'azmon'
  params: {
    location: location
    resourceSuffix: resourceSuffix
  }
  dependsOn: [
    rg
  ]
}

// Creating NSG for FHIR Subnet
module nsgfhirsubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(rg.name)
  name: nsgFHIRName
  params: {
    location: location
    nsgName: nsgFHIRName
    diagnosticWorkspaceId: monitor.outputs.logAnalyticsWorkspaceid
  }
}

// Creating FHIR route table
module routetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(rg.name)
  name: rtFHIRSubnetName
  params: {
    location: location
    rtName: rtFHIRSubnetName
  }
}

// Creating VNET
module vnetspoke 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: vnetSpokeName
  params: {
    location: location
    vnetAddressSpace: {
      addressPrefixes: spokeVNETaddPrefixes
    }
    vnetName: vnetSpokeName
    subnets: spokeSubnets
    diagnosticWorkspaceId: monitor.outputs.logAnalyticsWorkspaceid
  }
  dependsOn: [
    rg
  ]
}


// Creating Private DNS Zone for Key Vault
module privatednsVaultZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsVaultZone'
  params: {
    privateDNSZoneName: 'privatelink.vaultcore.azure.net'
  }
}

// Linking Private DNS Zone for Key Vault to Spoke VNet (required for AppGW to work properly to load Cert from a Private Endpoing Key Vault)
module privateDNSLinkVaultSpoke 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSLinkVaultSpoke'
  params: {
    privateDnsZoneName: privatednsVaultZone.outputs.privateDNSZoneName
    vnetId: vnetspoke.outputs.vnetId
    linkName: 'link-spoke'
  }
}

// APIM DNS Zones
// Creating Private DNS Zone for APIM
module privatednsazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsazureapinet'
  params: {
    privateDNSZoneName: 'azure-api.net'
  }
}

// Linking Private DNS Zone for APIM to VNet
module privatednsazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsazureapinetLink'
  params: {
    privateDnsZoneName: privatednsazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.outputs.vnetId
  }
}

// Creating Private DNS Zone for APIM portal
module privatednsportalazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsportalazureapinet'
  params: {
    privateDNSZoneName: 'portal.azure-api.net'
  }
}

// Linking Private DNS Zone for APIM portal to VNet
module privatednsportalazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsportalazureapinetLink'
  params: {
    privateDnsZoneName: privatednsportalazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.outputs.vnetId
  }
}

// Creating Private DNS Zone for APIM developer
module privatednsdeveloperazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsdeveloperazureapinet'
  params: {
    privateDNSZoneName: 'developer.azure-api.net'
  }
}

// Linking Private DNS Zone for APIM developer to VNet
module privatednsdeveloperazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsdeveloperazureapinetLink'
  params: {
    privateDnsZoneName: privatednsdeveloperazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.outputs.vnetId
  }
}

// Creating Private DNS Zone for APIM management
module privatednsmanagementazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsmanagementazureapinet'
  params: {
    privateDNSZoneName: 'management.azure-api.net'
  }
}

// Linking Private DNS Zone for APIM management to VNet
module privatednsmanagementazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsmanagementazureapinetLink'
  params: {
    privateDnsZoneName: privatednsmanagementazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.outputs.vnetId
  }
}

// Creating Private DNS Zone for APIM scm
module privatednsscmazureapinet 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsscmazureapinet'
  params: {
    privateDNSZoneName: 'scm.azure-api.net'
  }
}

// Linking Private DNS Zone for APIM scm to VNet
module privatednsscmazureapinetLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsscmazureapinetLink'
  params: {
    privateDnsZoneName: privatednsscmazureapinet.outputs.privateDNSZoneName
    vnetId: vnetspoke.outputs.vnetId
  }
}

// FHIR DNZ Zones
// Creating Private DNS Zone for FHIR
module privatednsfhir 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsfhir'
  params: {
    privateDNSZoneName: 'privatelink.azurehealthcareapis.com'
  }
}

// Linking Private DNS Zone for FHIR to VNet
module privatednsfhirLink 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsfhirLink'
  params: {
    privateDnsZoneName: privatednsfhir.outputs.privateDNSZoneName
    vnetId: vnetspoke.outputs.vnetId
  }
}

// Creating NSG for AppGW Subnet
module nsgappgwsubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(rg.name)
  name: nsgAppGWName
  params: {
    diagnosticWorkspaceId: monitor.outputs.logAnalyticsWorkspaceid
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

// Creating AppGW Route Table
module appgwroutetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(rg.name)
  name: rtAppGWSubnetName
  params: {
    location: location
    rtName: rtAppGWSubnetName
  }
}

module updateappgwNSG 'modules/vnet/updateSubnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'AppGWSubnetNamensgupdate'
  params: {
    rtId: appgwroutetable.outputs.routetableID
    vnetName: vnetSpokeName
    subnetName: appGatewaySubnetName
    nsgId: nsgappgwsubnet.outputs.nsgID
  }
  dependsOn: [
    vnetspoke
  ]
}

module updatefhirNSG 'modules/vnet/updateSubnet.bicep' = {
  scope: resourceGroup(rg.name)
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
  ]
}
