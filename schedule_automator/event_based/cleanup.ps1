Param(
    [Parameter (Mandatory = $true)]
    [String] $RUNBOOKSTAG,
    [Parameter (Mandatory = $true)]
    [String] $AUTOMATIONACCOUNTNAME,
    [Parameter (Mandatory = $true)]
    [String] $SUBSCRIPTIONID
)
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
$AzureContext = Set-AzContext -SubscriptionId $SUBSCRIPTIONID -DefaultProfile $AzureContext


$runbooks = Get-AzAutomationScheduledRunbook -ResourceGroupName "rg-management" -AutomationAccountName $AUTOMATIONACCOUNTNAME |  Where-Object { $_.ScheduleName -like "*$RUNBOOKSTAG*"}

foreach ($item in $runbooks) {
	Remove-AzAutomationSchedule -Name $item.ScheduleName -ResourceGroupName $item.ResourceGroupName -AUTOMATIONACCOUNTNAME $item.AutomationAccountName -Force
}
foreach ($item in $runbooks){
	Remove-AzAutomationRunbook -Name $item.RunbookName -ResourceGroupName $item.ResourceGroupName -AUTOMATIONACCOUNTNAME  $item.AutomationAccountName -Force
}
