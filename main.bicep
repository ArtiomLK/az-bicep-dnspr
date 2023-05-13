// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
@description('Az Resources tags')
param tags object = {}
@description('environment name. dev, qa, uat, stg, prod, etc.')
param env string

@description('the location for dnspr VNET and dns private dnspr - Azure DNS Private Resolver available in specific region, refer the documenation to select the supported region for this deployment. For more information https://docs.microsoft.com/azure/dns/dns-private-dnspr-overview#regional-availability')
param location string

// ------------------------------------------------------------------------------------------------
// Prerequisites params
// ------------------------------------------------------------------------------------------------
param dnspr_nsg_n string = 'nsg-default-${env}-${location}'

@description('id of the virtual network where DNS dnspr will be created')
param vnet_dnspr_n string = 'vnet-hub-extension-dns-${env}-${location}'
param vnet_dnspr_addr string //= /24

param snet_dnspr_in_n string = 'snet-dnspr-inbound'
param snet_dnspr_out_n string = 'snet-dnspr-outbound'
param snet_dnspr_in_addr string //= /28
param snet_dnspr_out_addr string //= /28

// ------------------------------------------------------------------------------------------------
// DNSPR Configuration parameters
// ------------------------------------------------------------------------------------------------
@description('name of the dns private dnspr')
param dnspr_n string

@description('name of the forwarding ruleset')
param fw_ruleset_n stringnsgDNSPR

@description('name of the forwarding rule name')
param fw_ruleset_rule_n string

@description('the target domain name for the forwarding ruleset')
param fw_ruleset_rule_domain_n string

@description('the list of target DNS servers ip address and the port number for conditional forwarding')
param fw_ruleset_rule_target_dns array

@description('name of the vnet link that links outbound endpoint with forwarding rule set')
var dnspr_vnet_link_n = 'vnetlink-${vnet_dnspr_n}'

// ------------------------------------------------------------------------------------------------
// Prerequisites
// ------------------------------------------------------------------------------------------------
module nsgDnspr 'components/nsg/nsgDefault.bicep' = {
  name: '${dnspr_nsg_n}-deployment'
  params: {
    name: dnspr_nsg_n
    tags: tags
    location: location
  }
}

resource vnetDnspr 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnet_dnspr_n
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_dnspr_addr
      ]
    }
    subnets: [
      {
        name: snet_dnspr_in_n
        properties: {
          addressPrefix: snet_dnspr_in_addr
          networkSecurityGroup: {
            id: nsgDnspr.outputs.id
          }
          delegations: [
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
        name: snet_dnspr_out_n
        properties: {
          addressPrefix: snet_dnspr_out_addr
          networkSecurityGroup: {
            id: nsgDnspr.outputs.id
          }
          delegations: [
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
  name: snet_dnspr_in_n
  location: location
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: vnetDnspr.properties.subnets[0].id
        }
      }
    ]
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: dnspr
  name: snet_dnspr_out_n
  location: location
  properties: {
    subnet: {
      id: vnetDnspr.properties.subnets[1].id
    }
  }
}

resource fwruleSet 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
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

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  parent: fwruleSet
  name: fw_ruleset_rule_n
  properties: {
    domainName: fw_ruleset_rule_domain_n
    targetDnsServers: fw_ruleset_rule_target_dns
  }
}

resource resolverLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
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
output vnet_dnspr_n string = vnet_dnspr_n
