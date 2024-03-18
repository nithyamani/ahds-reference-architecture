// Parameters
param fhirName string
param workspaceName string
var fhirLocation = 'northcentralus'

var tenantId = subscription().tenantId
var fhirservicename = '${workspaceName}/${fhirName}'
var loginURL = environment().authentication.loginEndpoint
var authority = '${loginURL}${tenantId}'
var audience = 'https://${workspaceName}-${fhirName}.fhir.azurehealthcareapis.com'
var serviceHost = '${workspaceName}-${fhirName}.fhir.azurehealthcareapis.com'

// Creating FHIR Workspace
resource Workspace 'Microsoft.HealthcareApis/workspaces@2022-06-01' = {
  name: workspaceName
  location: fhirLocation
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

// Creating FHIR service at Workspace
resource FHIR 'Microsoft.HealthcareApis/workspaces/fhirservices@2021-11-01' = {
  name: fhirservicename
  location:  fhirLocation
  kind: 'fhir-R4'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessPolicies: []
    authenticationConfiguration: {
      authority: authority
      audience: audience
      smartProxyEnabled: false
    }
    publicNetworkAccess: 'Disabled'
    }
    dependsOn: [
      Workspace
    ]
}

// Outputs
output fhirServiceURL string = audience
output fhirID string = FHIR.id
output fhirWorkspaceID string = Workspace.id
output serviceHost string = serviceHost
