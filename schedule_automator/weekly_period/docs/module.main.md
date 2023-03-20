## Information


**_generator:** @{name=bicep; version=0.15.31.15270; templateHash=11225063434985795887}
## Parameters
| Parameter Name | Parameter Type |Parameter Description | Parameter DefaultValue | Parameter AllowedValues |
| --- | --- | --- | --- | --- | 
 | automationAccountName| string |  |  |  |
 | days| array |  |  |  |
 | uniqueId| string |  | [guid(newGuid(), parameters('automationAccountName'))] |  |
## Resources
| Resource Name | Resource Type | Resource Comment |
| --- | --- | --- | 
 | [format('{0}/{1}', parameters('automationAccountName'), format('start-{0}-{1}', parameters('days')[copyIndex()].name, parameters('uniqueId')))]| Microsoft.Automation/automationAccounts/schedules |  | 
 | [format('{0}/{1}', parameters('automationAccountName'), format('end-{0}-{1}', parameters('days')[copyIndex()].name, parameters('uniqueId')))]| Microsoft.Automation/automationAccounts/schedules |  | 
