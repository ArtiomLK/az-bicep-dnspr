param peeringName string
param vnet_from_n string
param vnet_to_id string

resource vnetFrom 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnet_from_n
}

resource VNETPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2017-10-01' = {
  name: peeringName
  parent: vnetFrom
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet_to_id
    }
  }
}
