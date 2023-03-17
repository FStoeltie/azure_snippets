# Contains powershell deployment anc configuration methods to autostart a VM.
# Prerequisites: 
# - Existing RG
# - VM deployed
# - Existing Automation Account

# Method 1
# https://learn.microsoft.com/en-us/azure/automation/shared-resources/schedules
# Start with creating a new schedule to auto-start the VM

# Variables
$RESOURCE_GROUP = "resource_group_name"
# Automation account where the schedule will be created in
$AUTOMATION_ACCOUNT = "automation_account_name"
# Name of the schedule that will be created
$SCHEDULE_NAME = "new_schedule_name"
# Start time or datetime
$START_TIME = "start_time_24h_as_string"
[System.DayOfWeek[]]$WEEK_DAYS = @([System.DayOfWeek]::Monday..[System.DayOfWeek]::Friday)

# Create a new schedule in an existing Automation Account that runs 
# From monday to friday at a specified time
New-AzAutomationSchedule -AutomationAccountName $AUTOMATION_ACCOUNT `
    -Name $SCHEDULE_NAME `
    -StartTime $START_TIME ` 
    -ResourceGroupName $RESOURCE_GROUP `
    -DaysOfWeek $WEEK_DAYS `
    -WeekInterval 1