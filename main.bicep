var config = loadJsonContent('./config.json')
@secure()
param adminPassword string

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: config.nsgName
  location: config.location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}


resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: config.vnetName
  location: config.location
  dependsOn: [
    nsg
  ]
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: config.subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', config.nsgName)
          }
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${config.vmName}-pip'
  location: config.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${config.vmName}-nic'
  location: config.location
  dependsOn: [
    vnet
    publicIP
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', config.vnetName, config.subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: config.vmName
  location: config.location
  dependsOn: [
    nic
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: config.vmName
      adminUsername: config.adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output publicIPAddress string = reference(publicIP.id).ipAddress
