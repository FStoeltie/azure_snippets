targetScope = 'managementGroup'

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
  'Microsoft.DocumentDB/databaseAccounts'
  'Microsoft.Cache/Redis'
  'Microsoft.KeyVault/vault'
  'Microsoft.OperationalInsights/workspaces'
  'Microsoft.Insights/alertrules'
  'Microsoft.Automation/automationAccounts'
]

resource policyBlockVmSkus 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: 'pol-sandbox-001'
  properties: {
    displayName: '[pol-sandbox-001] BlockVmSkus'
    policyType: 'Custom'
    mode: 'All'
    description: 'Policy to block creation of VMs if they are not of type: ${allowedSkus}'
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
              equals: 'Microsoft.Compute/virtualMachines'
            }
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
  name: 'pol-sandbox-002'
  properties: {
    displayName: '[pol-sandbox-002] BlockIncorrectLocations'
    policyType: 'Custom'
    mode: 'All'
    description: 'Policy to block creation of resources if they are not in ${allowedLocations}'
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
  name: 'pol-sandbox-003'
  properties: {
    displayName: '[pol-sandbox-003] BlockResourceTypes'
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

resource policyBlockAppServiceSkus 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: 'pol-sandbox-004'
  properties: {
    displayName: '[pol-sandbox-004] BlockAppServiceSkus'
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
