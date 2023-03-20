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


## Sources


- [Original source part I](https://rabobank.jobs/en/techblog/coding-architecture/gijs-reijn-5-best-practices-for-using-azure-bicep/)

- [Original source part II](https://rabobank.jobs/en/techblog/coding-architecture/testing-best-practices-for-azure-bicep/)

- [PSRule for Azure](https://azure.github.io/PSRule.Rules.Azure/)

- [Azure Well Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)

- [Build automation for PS](https://github.com/nightroman/Invoke-Build)

- [Bicep Linter](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-config-linter)

- [Template Specs](https://github.com/Ba4bes/4bes-TemplateSpecsAzDo)

- [Markdown Generation for ARM & PS](https://msftplayground.com/2021/02/markdown-generation-for-arm-and-powershell/link)

- [Bootstrapping Wiki](https://en.wikipedia.org/wiki/Bootstrapping)