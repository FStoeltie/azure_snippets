targetScope = 'managementGroup'

param policyConfigurations object = {
  policyBlockVmSkus: {
    name: 'pol-sandbox-vm-001'
    metadata: {
      version: '0.1.0'
      category: 'category'
      source: 'source'
    }
  }
  policyBlockIncorrectLocations: {
    name: 'pol-sandbox-loc-002'
    metadata: {
      version: '0.1.0'
      category: 'category'
      source: 'source'
    }
  }
  policyBlockResourceTypes: {
    name: 'pol-sandbox-res-003'
    metadata: {
      version: '0.1.0'
      category: 'category'
      source: 'source'
    }
  }
  policyBlockAppServiceSkus: {
    name: 'pol-sandbox-app-004'
    metadata: {
      version: '0.1.0'
      category: 'category'
      source: 'source'
    }
  }
}

param allowedSkus array = [
  'Standard_B1ls'
  'Standard_A0'
  'Basic_A0'
  'Standard_B1s'
  'Standard_A1'
  'Basic_A1'
  'Standard_B1ms'
  'Standard_A1_v2'
  'Standard_D1_v2'
  'Standard_DS1_v2'
  'Standard_D1'
  'Standard_DS1'
  'Standard_A2'
  'Basic_A2'
  'Standard_B2s'
  'Standard_A2_v2'
]

param allowedLocations array = [ 'westeurope', 'uksouth' ]

param allowedResources array = [
  'Microsoft.Compute/virtualMachines'
  'Microsoft.Web/sites'
  'Microsoft.Storage/storageAccounts'
  'Microsoft.ContainerInstance/containerGroups'
  'Microsoft.ContainerService/managedClusters'
  'Microsoft.Network/virtualNetworks'
  'Microsoft.Network/loadBalancers'
  'Microsoft.Network/networkInterfaces'
  'Microsoft.Network/publicIPAddresses'
  'Microsoft.Network/applicationSecurityGroups'
  'Microsoft.Network/networkSecurityGroups'
  'Microsoft.RecoveryServices/vaults'
  'Microsoft.Web/serverfarms'
  'Microsoft.Sql/servers'
  'Microsoft.Sql/servers/databases'
  'Microsoft.Sql/servers/connectionPolicies'
  'Microsoft.Sql/servers/firewallrules'
  'Microsoft.DocumentDB/databaseAccounts'
  'Microsoft.Cache/Redis'
  'Microsoft.KeyVault/vault'
  'Microsoft.OperationalInsights/workspaces'
  'Microsoft.Insights/alertrules'
  'Microsoft.Automation/automationAccounts'
  'Microsoft.Authorization'
  'Microsoft.Subscriptions/resourceGroups'
]

resource policyBlockVmSkus 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: '${policyConfigurations.policyBlockVmSkus.name}'
  properties: { 
    displayName: '[${policyConfigurations.policyBlockVmSkus.name}] BlockVmSkus'
    policyType: 'Custom'
    mode: 'All'
    description: 'Policy to whitelist virtual machines SKUs'
    metadata: policyConfigurations.policyBlockVmSkus.metadata
    policyRule: {
      if: {
        allOf: [
          {
            not: {
              field: 'Microsoft.Compute/virtualMachines/properties/priority'
              equals: 'Spot'
            }
          }
          {
            field: 'type'
            equals: 'Microsoft.Compute/virtualMachines'
          
          }
          {
            not: {
              field: 'Microsoft.Compute/virtualMachines/sku.name'
              in: allowedSkus
            }
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}


resource policyBlockIncorrectLocations 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: '${policyConfigurations.policyBlockIncorrectLocations.name}'
  properties: {
    displayName: '[${policyConfigurations.policyBlockIncorrectLocations.name}] BlockIncorrectLocations'
    policyType: 'Custom'
    mode: 'All'
    description: 'Policy to whitelist regions'
    metadata: policyConfigurations.policyBlockIncorrectLocations.metadata
    policyRule: {
      if: {
        allOf: [
          {
            not: {
              field: 'location'
              in: allowedLocations
            }
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource policyBlockResourceTypes 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: policyConfigurations.policyBlockResourceTypes.name
  properties: {
    displayName: '[${policyConfigurations.policyBlockResourceTypes.name}] BlockResourceTypes'
    policyType: 'Custom'
    mode: 'All'
    description: 'Policy to whitelist resource types'
    metadata: policyConfigurations.policyBlockResourceTypes.metadata
    policyRule: {
      if: {
        allOf: [
          {
            not: {
              field: 'type'
              in: allowedResources
            }
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource policyBlockAppServiceSkus 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: policyConfigurations.policyBlockAppServiceSkus.name
  properties: {
    displayName: '[${policyConfigurations.policyBlockAppServiceSkus.name}] BlockAppServiceSkus'
    policyType: 'Custom'
    mode: 'All'
    description: 'Policy to block creation of resources if they are not one of the following: ${allowedResources}'
    metadata: {
      version: '0.1.0'
      category: 'category'
      source: 'source'
    }
    policyRule: {
      if: {
        allOf: [
          {
            not: {
              field: 'type'
              in: allowedResources
            }
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource PolicyInitiative 'Microsoft.Authorization/policySetDefinitions@2020-09-01' = {
  name: 'poli-sandbox-001'
  properties: {
    displayName: '[poli-sandbox-001] PolicyInitiative'
    policyType: 'Custom'
    description: 'Policy initiative for Sandbox Management Group'
    metadata: {
      version: '0.1.0'
      category: 'category'
      source: 'source'
    }
    policyDefinitions: [
      {
        policyDefinitionId: '${policyBlockResourceTypes.id}'
        policyDefinitionReferenceId: ''
      }
      {
        policyDefinitionId: '${policyBlockIncorrectLocations.id}'
        policyDefinitionReferenceId: ''
      }
      {
        policyDefinitionId: '${policyBlockVmSkus.id}'
        policyDefinitionReferenceId: ''
      }
    ]
  }
}
