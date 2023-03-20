
var templateSpecName = 'automationaccount'
var version = '0.0.1'
var releaseNotes = 'Template to deploy automation account'

param automationAccountName string
param days array
param uniqueId string = guid(newGuid(), automationAccountName)
resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' existing = {
  name: automationAccountName
}


resource dayStartSchedules 'Microsoft.Automation/automationAccounts/schedules@2019-06-01' = [for day in days : if (empty(day.startTime)) {
  name: 'start-${day.name}-${uniqueId}'
  parent: automationAccount
  properties: {
    advancedSchedule: {
      // monthDays: [
      //   int
      // ]
      // monthlyOccurrences: [
      //   {
      //     day: 'string'
      //     occurrence: int
      //   }
      // ]
      weekDays: [
        day.name
      ]
    }
    description: 'string'
    frequency: 'Week'
    startTime: day.startTime
  }
}]

resource dayEndSchedules 'Microsoft.Automation/automationAccounts/schedules@2019-06-01' = [for day in days : if (empty(day.endTime)) {
  name: 'end-${day.name}-${uniqueId}'
  parent: automationAccount
  properties: {
    advancedSchedule: {
      // monthDays: [
      //   int
      // ]
      // monthlyOccurrences: [
      //   {
      //     day: 'string'
      //     occurrence: int
      //   }
      // ]
      weekDays: [
        day.name
      ]
    }
    description: 'string'
    frequency: 'Week'
    startTime: day.startTime
  }
}]