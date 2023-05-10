param nsgName string
param tags object
param location string = resourceGroup().location

resource nsgAgw 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // inbound rules
      {
        name: 'AllowHttpsInBound'
        properties: {
          priority: 120
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 130
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 140
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          priority: 150
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
        }
      }
      // outbound rules
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          priority: 100
          destinationPortRanges: [
            '22'
            '3389'
          ]
          protocol: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          priority: 110
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          priority: 120
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowGetSessionInformation'
        properties: {
          priority: 130
          destinationPortRange: '80'
          protocol: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

output id string = nsgAgw.id
