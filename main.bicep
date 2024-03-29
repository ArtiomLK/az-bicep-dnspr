// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
@description('Az Resources tags')
param tags object = {}

@description('the location for dnspr VNET and dns private dnspr - Azure DNS Private Resolver available in specific region, refer the documenation to select the supported region for this deployment. For more information https://docs.microsoft.com/azure/dns/dns-private-dnspr-overview#regional-availability')
param location string

param deploy_outbound_endpoint bool = false

// ------------------------------------------------------------------------------------------------
// Prerequisites params
// ------------------------------------------------------------------------------------------------
param nsg_default_dnspr_n string = 'nsg-default-dnspr-${location}'

@description('id of the virtual network where DNS dnspr will be created')
param vnet_n string
param vnet_addr string //= /23

param dnspr_in_n string = 'inbound-endpoint-${location}'
param snet_in_n string = 'snet-dnspr-inbound'
param snet_in_addr string //= /24
param snet_in_ip string = '' //= n.n.n.4
param snet_out_n string = 'snet-dnspr-outbound'
param snet_out_addr string = '' //= /24

// ------------------------------------------------------------------------------------------------
// DNSPR Configuration parameters
// ------------------------------------------------------------------------------------------------
@description('name of the dns private dnspr')
param dnspr_n string

@description('name of the forwarding ruleset')
param fw_ruleset_n string = 'fw-ruleset-${dnspr_n}'

@description('name of the forwarding rule name')
param fw_ruleset_rule_n string = 'fw-ruleset-rule-${dnspr_n}'

@description('the target domain name for the forwarding ruleset')
param fw_ruleset_rule_domain_n string = 'contoso.com.'

@description('the list of target DNS servers ip address and the port number for conditional forwarding')
param fw_ruleset_rule_target_dns array = []

@description('name of the vnet link that links outbound endpoint with forwarding rule set')
var dnspr_vnet_link_n = 'vnetlink-${vnet_n}'

// ------------------------------------------------------------------------------------------------
// Prerequisites
// ------------------------------------------------------------------------------------------------
module nsgDefaultDnspr 'modules/nsg/nsgDefault.bicep' = {
  name: '${nsg_default_dnspr_n}-deployment'
  params: {
    name: nsg_default_dnspr_n
    tags: tags
    location: location
  }
}

resource vnetDnspr 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnet_n
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_addr
      ]
    }
    subnets: deploy_outbound_endpoint ? [
      {
        name: snet_in_n
        properties: {
          addressPrefix: snet_in_addr
          networkSecurityGroup: {
            id: nsgDefaultDnspr.outputs.id
          }
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: snet_out_n
        properties: {
          addressPrefix: snet_out_addr
          networkSecurityGroup: {
            id: nsgDefaultDnspr.outputs.id
          }
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
    ] : [
      {
        name: snet_in_n
        properties: {
          addressPrefix: snet_in_addr
          networkSecurityGroup: {
            id: nsgDefaultDnspr.outputs.id
          }
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource dnspr 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dnspr_n
  location: location
  properties: {
    virtualNetwork: {
      id: vnetDnspr.id
    }
  }
  tags: tags
}

resource inEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: dnspr
  name: dnspr_in_n
  location: location
  properties: {
    ipConfigurations: [
      empty(snet_in_ip) ? {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: vnetDnspr.properties.subnets[0].id
        }
      } : {
        privateIpAllocationMethod: 'Static'
        privateIpAddress: snet_in_ip
        subnet: {
          id: vnetDnspr.properties.subnets[0].id
        }
      }
    ]
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = if (deploy_outbound_endpoint) {
  parent: dnspr
  name: snet_out_n
  location: location
  properties: {
    subnet: {
      id: vnetDnspr.properties.subnets[1].id
    }
  }
}

resource fwruleSet 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = if (deploy_outbound_endpoint) {
  name: fw_ruleset_n
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outEndpoint.id
      }
    ]
  }
}

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = if (deploy_outbound_endpoint) {
  parent: fwruleSet
  name: fw_ruleset_rule_n
  properties: {
    domainName: fw_ruleset_rule_domain_n
    targetDnsServers: fw_ruleset_rule_target_dns
  }
}

resource dnsprLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = if (deploy_outbound_endpoint) {
  parent: fwruleSet
  name: dnspr_vnet_link_n
  properties: {
    virtualNetwork: {
      id: vnetDnspr.id
    }
  }
}

output dnspr_id string = dnspr.id
output vnet_dnspr_id string = vnetDnspr.id
output vnet_n string = vnet_n
