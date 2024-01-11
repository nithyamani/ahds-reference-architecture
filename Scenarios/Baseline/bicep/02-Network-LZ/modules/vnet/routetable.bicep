// Parameters
param rtName string
param location string = resourceGroup().location

// Creating Route Table
resource rt 'Microsoft.Network/routeTables@2021-02-01' = {
  name: rtName
  location: location
}

// Outputs
output routetableID string = rt.id
