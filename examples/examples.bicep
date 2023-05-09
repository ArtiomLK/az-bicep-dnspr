targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
// Sample tags parameters
var tags = {
  project: 'bicephub'
  env: 'dev'

}
// ------------------------------------------------------------------------------------------------
// Region 1
// ------------------------------------------------------------------------------------------------
param location string = 'eastus'

// DNSPR
param dnspr_n string = 'dnspr-dev-eastus'

// VNET
param vnet_dnspr_n string = 'vnet-hub-dev-eastus'
param vnet_dnspr_addr string = '10.10.0.0/24'

// SNET Inbound
param snet_dnspr_inbound_n string = 'snet-dnspr-inbound'
param snet_dnspr_inbound_addr string = '10.10.0.0/28'

// SNET Outbound
param snet_dnspr_outbound_n string = 'snet-dnspr-outbound'
param snet_dnspr_outbound_addr string = '10.10.0.16/28'

// ------------------------------------------------------------------------------------------------
// Prerequisites
// ------------------------------------------------------------------------------------------------

// resolver on hub vnet
resource vnetHubEastUs 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet_dnspr_n
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_dnspr_addr
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
    subnets: [
      {
        name: snet_dnspr_inbound_n
        properties: {
          addressPrefix: snet_dnspr_inbound_addr
          delegations:[
            {
              name:'Microsoft.Network.dnsResolvers'
              properties:{
                serviceName:'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: snet_dnspr_outbound_n
        properties: {
          addressPrefix: snet_dnspr_outbound_addr
          delegations:[
            {
              name:'Microsoft.Network.dnsResolvers'
              properties:{
                serviceName:'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
    ]
  }
  tags: tags
}

// ------------------------------------------------------------------------------------------------
// DNS Private Resolver
// ------------------------------------------------------------------------------------------------

module dnsprEastUs '../main.bicep' = {
  name: dnspr_n
  params: {
    dnspr_n: dnspr_n
    vnet_dnspr_n: vnet_dnspr_n
    snet_dnspr_inbound_n: snet_dnspr_inbound_n
    snet_dnspr_outbound_n: snet_dnspr_outbound_n
    location: location
    tags: tags
  }
  dependsOn: [
    vnetHubEastUs
  ]
}
