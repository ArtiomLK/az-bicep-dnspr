targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
// Sample tags parameters
var tags = {
  project: 'bicephub'
  env: 'dev'
}

param rgs array = ['${resourceGroup().name}', '${resourceGroup().name}']
param location string = 'eastus'

var locations = [location, 'westus3']

// ------------------------------------------------------------------------------------------------
// Topology Deployment parameters
// ------------------------------------------------------------------------------------------------
// VNET HUB Extension DNS
var vnet_hub_extension_dns_n = [for l in locations: 'vnet-hub-extension-dns-${tags.env}-${l}']
var vnet_hub_extension_dns_addr = [for i in range(1, length(locations)): '10.${i * 10}.0.0/23'] // 10.10.0.0/23, 10.20.0.0/23

// vnet-spoke-1
var vnet_spoke_1_names = [for l in locations: 'vnet-spoke-1-${tags.env}-${l}']
var snet_spoke_1_names = [for l in locations: 'snet-spoke-1']
var vnet_spoke_1_prefixes = [for i in range(1, length(locations)): '10.${i * 10}.2.0/24'] // 10.10.2.0/24, 10.20.2.0/24
var snet_spoke_1_prefixes = [for i in range(1, length(locations)): '10.${i * 10}.2.0/24'] // 10.10.2.0/24, 10.20.2.0/24

// ------------------------------------------------------------------------------------------------
// DNSPR Deployment parameters
// ------------------------------------------------------------------------------------------------
var dnspr_n = [for l in locations: 'dnspr-${tags.env}-${l}']

// SNET Inbound
var snet_dnspr_inbound_addr = [for i in range(1, length(locations)): '10.${i * 10}.0.0/24'] // 10.10.0.0/24, 10.20.0.0/24
var snet_dnspr_inbound_ip = [for i in range(1, length(locations)): '10.${i * 10}.0.4'] // 10.10.0.4, 10.20.0.4

// SNET Outbound
var snet_dnspr_outbound_addr = [for i in range(1, length(locations)): '10.${i * 10}.1.0/28'] // 10.10.1.0/24, 10.20.1.0/24

// Forwarding Ruleset
var fw_ruleset_n = [for l in locations: 'fw-ruleset-${tags.env}-${l}']
var fw_ruleset_rule_n = [for l in locations: 'contosocom']
var fw_ruleset_rule_domain_n = [for l in locations: 'contoso.com.']
var fw_ruleset_rule_target_dns = [
  for l in locations: [
    {
      ipaddress: '10.0.0.4'
      port: 53
    }
    {
      ipaddress: '10.0.0.5'
      port: 53
    }
  ]
]

// ------------------------------------------------------------------------------------------------
// Prerequisites
// ------------------------------------------------------------------------------------------------
// NSG - Default
module nsgDefault '../modules/nsg/nsgDefault.bicep' = [
  for i in range(0, length(locations)): {
    scope: resourceGroup(rgs[i])
    name: 'nsg-default-${locations[i]}'
    params: {
      tags: tags
      location: locations[i]
      name: 'nsg-default-${locations[i]}'
    }
  }
]

// ------------------------------------------------------------------------------------------------
// Deploy Spokes Vnets
// ------------------------------------------------------------------------------------------------
module vnetSpoke1 '../modules/vnet/vnet.bicep' = [
  for i in range(0, length(vnet_spoke_1_names)): {
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
  }
]

// ------------------------------------------------------------------------------------------------
// Deploy vNet peerings
// ------------------------------------------------------------------------------------------------
module hubToSpokePeering '../modules/vnet/peer.bicep' = [
  for i in range(0, length(vnet_spoke_1_names)): {
    scope: resourceGroup(rgs[i])
    name: take('${vnet_hub_extension_dns_n[i]}-to-${vnet_spoke_1_names[i]}', 64)
    params: {
      vnet_from_n: dnsprInboundOutbound[i].outputs.vnet_n
      vnet_to_id: vnetSpoke1[i].outputs.id
      peeringName: '${vnet_hub_extension_dns_n[i]}-to-${vnet_spoke_1_names[i]}'
    }
  }
]

module spokeToHubPeering '../modules/vnet/peer.bicep' = [
  for i in range(0, length(vnet_spoke_1_names)): {
    scope: resourceGroup(rgs[i])
    name: take('${vnet_spoke_1_names[i]}-to-${vnet_hub_extension_dns_n[i]}', 64)
    params: {
      vnet_from_n: vnet_spoke_1_names[i]
      vnet_to_id: dnsprInboundOutbound[i].outputs.vnet_dnspr_id
      peeringName: '${vnet_spoke_1_names[i]}-to-${vnet_hub_extension_dns_n[i]}'
    }
  }
]

// ------------------------------------------------------------------------------------------------
// DNS Private Resolver
// ------------------------------------------------------------------------------------------------
module dnsprInboundOutbound '../main.bicep' = [
  for i in range(0, length(locations)): {
    scope: resourceGroup(rgs[i])
    name: dnspr_n[i]
    params: {
      dnspr_n: dnspr_n[i]

      vnet_n: vnet_hub_extension_dns_n[i]
      vnet_addr: vnet_hub_extension_dns_addr[i]
      snet_in_addr: snet_dnspr_inbound_addr[i]
      snet_out_addr: snet_dnspr_outbound_addr[i]
      snet_in_ip: snet_dnspr_inbound_ip[i]

      deploy_outbound_endpoint: true
      fw_ruleset_n: fw_ruleset_n[i]
      fw_ruleset_rule_n: fw_ruleset_rule_n[i]
      fw_ruleset_rule_domain_n: fw_ruleset_rule_domain_n[i]
      fw_ruleset_rule_target_dns: fw_ruleset_rule_target_dns[i]

      location: locations[i]
      tags: tags
    }
  }
]

// ------------------------------------------------------------------------------------------------
// DNS Private Resolver
// ------------------------------------------------------------------------------------------------
module dnsprInbound '../main.bicep' = {
  scope: resourceGroup(rgs[0])
  name: 'dnspr-inbound-deployment'
  params: {
    dnspr_n: 'dnspr-inbound-${locations[0]}'

    vnet_n: 'vnet-dnspr-inbound-${locations[0]}'
    vnet_addr: '10.100.0.0/23'
    snet_in_addr: '10.100.0.0/24'
    snet_in_ip: '10.100.0.4'

    location: locations[0]
    tags: tags
  }
}
