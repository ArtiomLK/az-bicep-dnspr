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

// DNSPR
param dnspr_n string = 'dnspr-resolver'

// VNET
param vnet_dnspr_n string = 'vnet-dnsresolver'
param vnet_dnspr_addr string = '10.7.0.0/24'

// SNET Inbound
param snet_dnspr_inbound_n string = 'snet-dnspr-inbound'
param snet_dnspr_inbound_addr string = '10.7.0.0/28'

// SNET Outbound
param snet_dnspr_outbound_n string = 'snet-dnspr-outbound'
param snet_dnspr_outbound_addr string = '10.7.0.16/28'

// ------------------------------------------------------------------------------------------------
// Prerequisites
// ------------------------------------------------------------------------------------------------

// resolver vnet
resource resolverVnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
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

module dnspr '../main.bicep' = {
  name: 'dnspr'
  params: {
    dnspr_n: dnspr_n
    vnet_dnspr_id: resolverVnet.id
    snet_dnspr_inbound_n: snet_dnspr_inbound_n
    snet_dnspr_outbound_n: snet_dnspr_outbound_n
    location: location
    tags: tags
  }
}
