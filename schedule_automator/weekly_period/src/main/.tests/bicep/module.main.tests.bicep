@description('Configures the location to deploy the Azure resources.')
//param location string = resourceGroup().location

// Test with required parameters
module test_storage_params '../../modules/module.main.bicep' = {
  name: 'testparams'
  
  params: {
    days: [
      {
        name: 'monday'
        startTime: '08:30:00'
        endTime: '17:30:00'
      }
    ]
    automationAccountName: 'test001'
    // location: location
    // tags: {
    //   env: 'test'
    // }
  }
}
