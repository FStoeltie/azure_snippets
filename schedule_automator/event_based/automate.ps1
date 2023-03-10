Param(
    [Parameter (Mandatory = $true)]
    [String] $ScheduleGroup,
    [Parameter (Mandatory = $true)]
    [String] $SubscriptionId
    [Parameter (Mandatory = $true)]
    [String] $Action
)
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
$AzureContext = Set-AzContext -SubscriptionId $SubscriptionId -DefaultProfile $AzureContext

# Automation
$VIRTUAL_MACHINES = Get-AzVM | Where-Object { $_.Tags.Values -like "$($ScheduleGroup)" }

if ($Action -eq "start")
{
  # Start the Virtual Machines that contain the given tag value
  $VIRTUAL_MACHINES | Start-AzVM
} elseif ($Action -eq "stop") {
  # Stop the Virtual Machines that contain the given tag value
  $VIRTUAL_MACHINES | Stop-AzVM
}


# Write the names of the Virtual Machines that were started to the output stream
Write-Output $VIRTUAL_MACHINES.Name
