param tags object
param vnet_n string
param vnet_addr string
param defaultNsgId string
param subnets array
param location string = resourceGroup().location

resource vnetDeployed 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnet_n
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_addr
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
        networkSecurityGroup: {
          id: empty(subnet.nsgId) ? defaultNsgId : subnet.nsgId
        }
      }
    }]
  }
}

output id string = vnetDeployed.id
