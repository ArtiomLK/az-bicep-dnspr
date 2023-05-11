targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
// Sample tags parameters
var tags = {
  project: 'bicephub'
  env: 'dev'
}

param rgs array = ['rg-azure-bicep-dnspr-eastus', 'rg-azure-bicep-dnspr-westus3']
var pdnsz_rg_n = 'rg-azure-bicep-dnspr'
param locations array = ['eastus', 'westus3']

// ------------------------------------------------------------------------------------------------
// Topology Deployment parameters
// ------------------------------------------------------------------------------------------------
// HUB VNET
var vnet_hub_n = [for l in locations: 'vnet-hub-${tags.env}-${l}']
var vnet_hub_addr = [for i in range(1, length(locations)): '10.${i*10}.0.0/24']   // 10.10.0.0/24, 10.20.0.0/24

// vnet-spoke-1
var vnet_spoke_1_names = [for l in locations: 'vnet-spoke-1-${tags.env}-${l}']
var snet_spoke_1_names = [for l in locations: 'snet-spoke-1']
var vnet_spoke_1_prefixes = [for i in range(1, length(locations)):  '10.${i*10}.1.0/24']   // 10.10.1.0/24, 10.20.1.0/24
var snet_spoke_1_prefixes = [for i in range(1, length(locations)): '10.${i*10}.1.0/24']   // 10.10.1.0/24, 10.20.1.0/24

// ------------------------------------------------------------------------------------------------
// DNSPR Deployment parameters
// ------------------------------------------------------------------------------------------------
// DNSPR
var dnspr_n = [for l in locations: 'dnspr-${tags.env}-${l}']

// SNET Inbound
var snet_dnspr_inbound_n = [for l in locations: 'snet-dnspr-inbound']
var snet_dnspr_inbound_addr = [for i in range(1, length(locations)): '10.${i*10}.0.0/28']   // 10.10.0.0/28, 10.20.0.0/28

// SNET Outbound
var snet_dnspr_outbound_n = [for l in locations: 'snet-dnspr-outbound']
var snet_dnspr_outbound_addr = [for i in range(1, length(locations)): '10.${i*10}.0.16/28']   // 10.10.0.16/28, 10.20.0.16/28

// Forwarding Ruleset
var fw_ruleset_n = [for l in locations: 'fw-ruleset-${tags.env}-${l}']
var fw_ruleset_rule_n = [for l in locations: 'contosocom']
var fw_ruleset_rule_domain_n = [for l in locations: 'contoso.com.']
var fw_ruleset_rule_target_dns = [for l in locations: [
  {
    ipaddress: '10.0.0.4'
    port: 53
  }
  {
    ipaddress: '10.0.0.5'
    port: 53
  }
]]

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

// ------------------------------------------------------------------------------------------------
// Deploy vNet peerings
// ------------------------------------------------------------------------------------------------
module hubToSpokePeering '../components/vnet/peer.bicep' = [for i in range(0, length(vnet_spoke_1_names)) : {
  scope: resourceGroup(rgs[i])
  name: 'hub-to-spoke-peering-deployment'
  params: {
    vnet_from_n: vnet_hub_n[i]
    vnet_to_id: vnetSpoke1[i].outputs.id
    peeringName: '${vnet_hub_n[i]}-to-${vnet_spoke_1_names[i]}'
  }
}]

module spokeToHubPeering '../components/vnet/peer.bicep' = [for i in range(0, length(vnet_spoke_1_names)) : {
  scope: resourceGroup(rgs[i])
  name: 'spoke-to-hub-peering-deployment'
  params: {
    vnet_from_n: vnet_spoke_1_names[i]
    vnet_to_id: vnetHubs[i].outputs.id
    peeringName: '${vnet_spoke_1_names[i]}-to-${vnet_hub_n[i]}'
  }
}]

// ------------------------------------------------------------------------------------------------
// Deploy pdnsz
// ------------------------------------------------------------------------------------------------
module pdnsz 'br:bicephubdev.azurecr.io/bicep/modules/pdnsz:a08deb867263fbdad01f529acf70fe0a9e2703f4' =  {
  scope: resourceGroup(pdnsz_rg_n)
  name: 'pdnsz-deployment'
  params: {
    vnet_ids: [vnetHubs[0].outputs.id, vnetHubs[1].outputs.id]
    tags: tags
  }
}

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
    fw_ruleset_n: fw_ruleset_n[i]
    fw_ruleset_rule_n: fw_ruleset_rule_n[i]
    fw_ruleset_rule_domain_n: fw_ruleset_rule_domain_n[i]
    fw_ruleset_rule_target_dns: fw_ruleset_rule_target_dns[i]
    location: locations[i]
    tags: tags
  }
  dependsOn: [
    vnetHubs
  ]
}]
