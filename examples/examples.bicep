targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
// Sample tags parameters
var tags = {
  project: 'bicephub'
  env: 'dev'
}

param location string = 'eastus'

// ------------------------------------------------------------------------------------------------
// DNS Private Resolver
// ------------------------------------------------------------------------------------------------

module dnspr '../main.bicep' = {
  name: 'dnspr'
  params: {
    location: location
    tags: tags
  }
}
