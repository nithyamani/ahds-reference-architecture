// Parameters
param name string
param keyVaultsku string
param tenantId string
param location string = resourceGroup().location
param networkAction string = 'Deny'

// Creating Key Vault
resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: keyVaultsku
    }
    accessPolicies: []
    tenantId: tenantId
    enabledForDiskEncryption: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: networkAction
    }
  }
}

// Outputs
output keyvaultId string = keyvault.id
output keyvaultName string = keyvault.name
