targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
// Sample tags parameters
var tags = {
  project_n: 'bicephub'
  env: 'dev'

}
// ------------------------------------------------------------------------------------------------
// DNSPR Deployment parameters
// ------------------------------------------------------------------------------------------------
param rgs array = ['rg-azure-bicep-dnspr-eastus', 'rg-azure-bicep-dnspr-westus3']
param locations array = ['eastus', 'westus3']

// DNSPR
var dnspr_n = [for l in locations: 'dnspr-${tags.env}-${l}']

// HUB VNET
var vnet_hub_n = [for l in locations: 'vnet-hub-${tags.env}-${l}']
var vnet_hub_addr = [for i in range(1, length(locations)): '10.${i*10}.0.0/24']   // 10.10.0.0/24, 10.20.0.0/24

// SNET Inbound
var snet_dnspr_inbound_n = [for l in locations: 'snet-dnspr-inbound']
var snet_dnspr_inbound_addr = [for i in range(1, length(locations)): '10.${i*10}.0.0/28']   // 10.10.0.0/28, 10.20.0.0/28

// SNET Outbound
var snet_dnspr_outbound_n = [for l in locations: 'snet-dnspr-outbound']
var snet_dnspr_outbound_addr = [for i in range(1, length(locations)): '10.${i*10}.0.16/28']   // 10.10.0.16/28, 10.20.0.16/28

// vnet-spoke-1
var vnet_spoke_1_names = [for l in locations: 'vnet-spoke-1-${tags.env}-${l}']
var snet_spoke_1_names = [for l in locations: 'snet-spoke-1']
var vnet_spoke_1_prefixes = [for i in range(1, length(locations)):  '10.${i*10}.1.0/24']   // 10.10.1.0/24, 10.20.1.0/24
var snet_spoke_1_prefixes = [for i in range(1, length(locations)): '10.${i*10}.0.0/24']   // 10.10.1.0/24, 10.20.1.0/24

// ------------------------------------------------------------------------------------------------
// Prerequisites
// ------------------------------------------------------------------------------------------------

// NSG - Default
module nsgDefault '../components/nsg/nsgDefault.bicep' = [for i in range(0, length(locations)) : {
  scope: resourceGroup(rgs[i])
  name: 'nsg-default-${locations[i]}'
  params: {
    tags: tags
    location: locations[i]
    name: 'nsg-default-${locations[i]}'
  }
}]

// ------------------------------------------------------------------------------------------------
// Deploy Hub Vnets
// ------------------------------------------------------------------------------------------------
module vnetHubs '../components/vnet/vnet.bicep' = [for i in range(0, length(vnet_hub_n)) : {
  scope: resourceGroup(rgs[i])
  name: vnet_hub_n[i]
  params: {
    vnet_n: vnet_hub_n[i]
    vnet_addr: vnet_hub_addr[i]
    subnets: [
      {
        name: snet_dnspr_inbound_n[i]
        subnetPrefix: snet_dnspr_inbound_addr[i]
        nsgId: nsgDefault[i].outputs.id
        delegations: [
          {
            name:'Microsoft.Network.dnsResolvers'
            properties:{
              serviceName:'Microsoft.Network/dnsResolvers'
            }
          }
        ]
      }
      {
        name: snet_dnspr_outbound_n[i]
        subnetPrefix: snet_dnspr_outbound_addr[i]
        nsgId: nsgDefault[i].outputs.id
        delegations: [
          {
            name:'Microsoft.Network.dnsResolvers'
            properties:{
              serviceName:'Microsoft.Network/dnsResolvers'
            }
          }
        ]
      }
    ]
    defaultNsgId: nsgDefault[i].outputs.id
    location: locations[i]
    tags: tags
  }
  dependsOn: [
    nsgDefault
  ]
}]

// ------------------------------------------------------------------------------------------------
// Deploy Spokes Vnets
// ------------------------------------------------------------------------------------------------
module vnetSpoke1 '../components/vnet/vnet.bicep' = [for i in range(0, length(vnet_spoke_1_names)) : {
  scope: resourceGroup(rgs[i])
  name: vnet_spoke_1_names[i]
  params: {
    vnet_n: vnet_spoke_1_names[i]
    vnet_addr: vnet_spoke_1_prefixes[i]
    subnets: [
      {
        name: snet_spoke_1_names[i]
        subnetPrefix: snet_spoke_1_prefixes[i]
        nsgId: nsgDefault[i].outputs.id
        delegations: []
      }
    ]
    defaultNsgId: nsgDefault[i].outputs.id
    location: locations[i]
    tags: tags
  }
  dependsOn: [
    nsgDefault
  ]
}]


// // VNET HUB - with DNSPR snets
// resource vnetHubEastUs 'Microsoft.Network/virtualNetworks@2022-01-01' = [for i in range(0, length(vnet_hub_n)): {
//   name: vnet_hub_n[i]
//   location: locations[i]
//   properties: {
//     addressSpace: {
//       addressPrefixes: [
//         vnet_hub_addr[i]
//       ]
//     }
//     enableDdosProtection: false
//     enableVmProtection: false
//     subnets: [
//       {
//         name: snet_dnspr_inbound_n[i]
//         properties: {
//           addressPrefix: snet_dnspr_inbound_addr[i]
//           delegations:[
//             {
//               name:'Microsoft.Network.dnsResolvers'
//               properties:{
//                 serviceName:'Microsoft.Network/dnsResolvers'
//               }
//             }
//           ]
//         }
//       }
//       {
//         name: snet_dnspr_outbound_n[i]
//         properties: {
//           addressPrefix: snet_dnspr_outbound_addr[i]
//           delegations:[
//             {
//               name:'Microsoft.Network.dnsResolvers'
//               properties:{
//                 serviceName:'Microsoft.Network/dnsResolvers'
//               }
//             }
//           ]
//         }
//       }
//     ]
//   }
//   tags: tags
// }]

// ------------------------------------------------------------------------------------------------
// DNS Private Resolver
// ------------------------------------------------------------------------------------------------
module dnspr '../main.bicep' = [for i in range(0, length(locations)):  {
  scope: resourceGroup(rgs[i])
  name: dnspr_n[i]
  params: {
    dnspr_n: dnspr_n[i]
    vnet_dnspr_n: vnet_hub_n[i]
    snet_dnspr_inbound_n: snet_dnspr_inbound_n[i]
    snet_dnspr_outbound_n: snet_dnspr_outbound_n[i]
    location: locations[i]
    tags: tags
  }
  dependsOn: [
    vnetHubs
  ]
}]
