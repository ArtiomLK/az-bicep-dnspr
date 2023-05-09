// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
@description('Az Resources tags')
param tags object = {}

@description('the location for resolver VNET and dns private resolver - Azure DNS Private Resolver available in specific region, refer the documenation to select the supported region for this deployment. For more information https://docs.microsoft.com/azure/dns/dns-private-resolver-overview#regional-availability')
@allowed([
  'australiaeast'
  'uksouth'
  'northeurope'
  'southcentralus'
  'westus3'
  'eastus'
  'northcentralus'
  'westcentralus'
  'eastus2'
  'westeurope'
  'centralus'
  'canadacentral'
  'brazilsouth'
  'francecentral'
  'swedencentral'
  'switzerlandnorth'
  'eastasia'
  'southeastasia'
  'japaneast'
  'koreacentral'
  'southafricanorth'
  'centralindia'
])
param location string

// ------------------------------------------------------------------------------------------------
// DNSPR Configuration parameters
// ------------------------------------------------------------------------------------------------
@description('name of the dns private resolver')
param dnspr_n string

// VNET and subnet for DNSPR
@description('id of the virtual network where DNS resolver will be created')
param vnet_dnspr_id string

@description('name of the subnet that will be used for private resolver inbound endpoint')
param snet_dnspr_inbound_n string

@description('name of the subnet that will be used for private resolver outbound endpoint')
param snet_dnspr_outbound_n string

@description('name of the vnet link that links outbound endpoint with forwarding rule set')
param resolvervnetlink string = 'vnetlink'

// Forwarding ruleset and forwarding rule
@description('name of the forwarding ruleset')
param forwardingRulesetName string = 'forwardingRule'

@description('name of the forwarding rule name')
param forwardingRuleName string = 'contosocom'

@description('the target domain name for the forwarding ruleset')
param DomainName string = 'contoso.com.'

@description('the list of target DNS servers ip address and the port number for conditional forwarding')
param targetDNS array = [
    {
      ipaddress: '10.0.0.4'
      port: 53
    }
    {
      ipaddress: '10.0.0.5'
      port: 53
    }
  ]

resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dnspr_n
  location: location
  properties: {
    virtualNetwork: {
      id: vnet_dnspr_id
    }
  }
  tags: tags
}

resource inEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: resolver
  name: snet_dnspr_inbound_n
  location: location
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: '${vnet_dnspr_id}/subnets/${snet_dnspr_inbound_n}'
        }
      }
    ]
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: resolver
  name: snet_dnspr_outbound_n
  location: location
  properties: {
    subnet: {
      id: '${vnet_dnspr_id}/subnets/${snet_dnspr_outbound_n}'
    }
  }
}

resource fwruleSet 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: forwardingRulesetName
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outEndpoint.id
      }
    ]
  }
}

resource resolverLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  parent: fwruleSet
  name: resolvervnetlink
  properties: {
    virtualNetwork: {
      id: vnet_dnspr_id
    }
  }
}

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  parent: fwruleSet
  name: forwardingRuleName
  properties: {
    domainName: DomainName
    targetDnsServers: targetDNS
  }
}
