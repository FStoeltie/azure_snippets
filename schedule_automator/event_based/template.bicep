param automationAccountName  string = 'prod-euw-01-management-automation'

param startTimes array
param stopTimes array
param resourceLocation string = 'WestEurope'
param uniqueId string = '${uniqueString(subscription().subscriptionId)}-${newGuid()}'
param test string = newGuid()
param cleanUpTime string 
param automationPSUrl string
param cleanupPSUrl string
var stringArray = [for startTime in startTimes: '${uniqueId}-${startTime.name}-start']
var concatIds = string(stringArray)

targetScope = 'resourceGroup'
// Get the existing automation Account by AccounName - prerequisite
resource automationAccount 'Microsoft.Automation/automationAccounts@2019-06-01' existing =  {
  name: automationAccountName

}


// Create a runbook that contains the start/stop script
resource automationRunbookVMAutomate 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: 'automation-${uniqueId}'
  location: resourceLocation
  tags: {
    eventIdentifier: uniqueId 
  }
  properties: {
    logVerbose: true
    logProgress: true
    runbookType: 'PowerShell'
    publishContentLink: {
      uri: automationPSUrl
      version: '1.0.0.0' 
    }
    description: '''
      Input parameters: 
      The runbook containing the Powershell script to start and stop Virtual Machines. 
      Only VM\'s with the tag value are turned on or off based on the action parameter.
    ''' 

  }
} 

// Create Automation schedules that are supplied by the parameters.json file
resource automationScheduleStart 'Microsoft.Automation/automationAccounts/schedules@2019-06-01' = [for startTime in startTimes:{
  
  dependsOn: [
    automationRunbookVMAutomate
  ]
  
  parent: automationAccount
  name: '${startTime.name}-start-${uniqueId}'
  properties: {
    description: 'description'
    startTime: startTime.startTime
    frequency: 'OneTime'
    timeZone: 'W. Europe Standard Time'
    
  }
}]

resource automationScheduleStop 'Microsoft.Automation/automationAccounts/schedules@2019-06-01' = [for stopTime in stopTimes:{
  
  dependsOn: [
    automationRunbookVMAutomate
  ]
  
  parent: automationAccount
  name: '${stopTime.name}-stop-${uniqueId}'
  properties: {
    description: 'description'
    startTime: stopTime.startTime
    frequency: 'OneTime'
    timeZone: 'W. Europe Standard Time'

  }
}]

// Schedule Start VM jobs (Link between Schedules and runbooks that are run by the schedules)
resource automationJobScheduleStart 'Microsoft.Automation/automationAccounts/jobSchedules@2019-06-01' = [for startTime in startTimes:{
  dependsOn: [
    automationScheduleStart
  ]
  parent: automationAccount
  name: guid(test, uniqueId, '-job-', startTime.name, '-start')
  
  properties: {
    parameters: {
        ScheduleGroup: uniqueId
        SubscriptionId: subscription().subscriptionId
        Action: 'start'
    }
    schedule: {
      name: '${startTime.name}-start-${uniqueId}'
    }
    runbook: {
      name: 'automation-${uniqueId}'
    }
  }
}]

// Schedule Stop VM jobs (Link between Schedules and runbooks that are run by the schedules)
resource automationJobScheduleStop 'Microsoft.Automation/automationAccounts/jobSchedules@2019-06-01' = [for stopTime in stopTimes:{
  dependsOn: [
    automationScheduleStop
  ]
  parent: automationAccount
  name: guid(test, uniqueId, '-job-', stopTime.name, '-stop')
  
  properties: {
    parameters: {
        ScheduleGroup: uniqueId
        SubscriptionId: subscription().subscriptionId
        Action: 'stop'
    }
    schedule: {
      name: '${stopTime.name}-stop-${uniqueId}'
    }
    runbook: {
      name: 'automation-${uniqueId}'
    }
  }
}]

// Cleanup all resources at a specific date
// Automation runbook containing Powershell script to remove all resources that are created above
resource automationRunbookCleanup 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: 'automation-cleanup-${uniqueId}'
  location: resourceLocation
  properties: {
    logVerbose: true
    logProgress: true
    runbookType: 'PowerShell'
    publishContentLink: {
      uri: cleanupPSUrl
      version: '1.0.0.0'
    }
    description: 'description'
  }
}

// Scheduled date and time to trigger the cleanup Powershell script
resource automationScheduleCleanup 'Microsoft.Automation/automationAccounts/schedules@2019-06-01' = {
  parent: automationAccount
  dependsOn: [
    automationRunbookCleanup
    automationJobScheduleStart
    automationJobScheduleStop
    automationRunbookVMAutomate
  ]

  name: 'automationCleanup-${uniqueId}'
  properties: {
    description: 'description'
    startTime: cleanUpTime
    frequency: 'OneTime'
    timeZone: 'W. Europe Standard Time'
  }
}

// Link between Schedule (trigger) and Runbook (Powershell cleanup script)
resource automationJobScheduleCleanup 'Microsoft.Automation/automationAccounts/jobSchedules@2019-06-01' = {
  parent: automationAccount
  dependsOn: [
    automationRunbookCleanup
    automationScheduleCleanup
  ]
  name: guid(test, uniqueId, '-job-', 'Cleanup')
  properties: {
    parameters: {
      RUNBOOKSTAG: uniqueId
      AUTOMATIONACCOUNTNAME: automationAccount.name
      SUBSCRIPTIONID: subscription().subscriptionId
      CleanupSchedules: concatIds
    }
    schedule: {
      name: automationScheduleCleanup.name
    }
    runbook: {
      name: automationRunbookCleanup.name
    }
  }
}
