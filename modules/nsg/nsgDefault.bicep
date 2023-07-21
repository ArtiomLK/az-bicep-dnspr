param tags object
param location string = resourceGroup().location
param name string

resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: empty(name) ? 'nsg-default' : name
  location: location
  properties: {}
  tags: tags
}

output id string = nsgDefault.id
