Param(
    [Parameter (Mandatory = $true)]
    [String] $RunbooksTag,
    [Parameter (Mandatory = $true)]
    [String] $AutomationAccountName
)
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
$AzureContext = Set-AzContext -SubscriptionId $SubscriptionId -DefaultProfile $AzureContext


$runbooks = Get-AzAutomationScheduledRunbook -ResourceGroupName "rg-management" -AutomationAccountName $AutomationAccountName |  Where-Object { $_.ScheduleName -like "*$RunbooksTag*"}

foreach ($item in $runbooks) {
	Remove-AzAutomationSchedule -Name $item.ScheduleName -ResourceGroupName $item.ResourceGroupName -AutomationAccountName $item.AutomationAccountName -Force
}
foreach ($item in $runbooks){
	Remove-AzAutomationRunbook -Name $item.RunbookName -ResourceGroupName $item.ResourceGroupName -AutomationAccountName  $item.AutomationAccountName -Force
}
