[CmdletBinding()]

Param (
    [Parameter(Mandatory = $False, HelpMessage='Specify the source directory to retrieve modules')]
    [string]$TemplatePath = "$BuildRoot\src",
    [Parameter(Mandatory = $False, HelpMessage='Specify the output directory to build ARM template')]
    [string]$BuildDirectory = "$BuildRoot\build",
    [Parameter(Mandatory = $False, HelpMessage='Specify the location of the rescoure group')]
    [string]$Location = "westeurope",
    [Parameter(Mandatory = $False, HelpMessage='Specify the resource group to publish and deploy')]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $False, HelpMessage='Specify the output directory to test ARM template')]
    [string]$TestDirectory = "$BuildRoot\testResults\",
    [Parameter(Mandatory = $False, HelpMessage='Specify the template output folder to build documentation')]
    [string]$DocsDirectory = "$BuildRoot\docs",
    $ExcludeFolders = '',
    [bool]$KeepStructure = $false,
    [bool]$IncludeWikiTOC = $false
)


task Clean {
    Remove-Item -Path $BuildDirectory -Force -ErrorAction SilentlyContinue -Recurse
}

task BuildBicep {
    Write-Build Yellow "Retrieving all Bicep file(s) from: $TemplatePath"
    $Templates = (Get-ChildItem -Path $TemplatePath -Recurse -Include *.bicep) 

    foreach ($Template in $Templates) {
        Write-Build Yellow "Building bicep: $($Template.FullName)"
        if (-not (Test-Path $BuildDirectory)) {
            New-Item -Path $BuildDirectory -ItemType Directory -Force
        }
        
        bicep build $Template.FullName --outdir $BuildDirectory
        $PackagePath = "$BuildDirectory\$($Template.Name.Replace('.bicep', '.json'))".ToString()
        $script:PackageLocation += $PackagePath
        Write-Build Yellow "Output: $PackagePath"
    }
}

task TestBicep {
    if (-not (Test-Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force
    }

    $Packages = (Get-ChildItem -Path $BuildDirectory -Filter *.json | Where-Object {$_.Name -like "module.*"}).FullName
    Write-Build Yellow "Retrieved number of modules to test: $($Packages.Count)"
    
    $ModulePath = Get-ChildItem -Path $TestDirectory -Filter arm-ttk.psm1 -Recurse 
    if (-not $ModulePath) {
        Write-Build Yellow "ARM Test Toolkit was not found, downloading... "
        $ARMTTKUrl = 'https://azurequickstartsservice.blob.core.windows.net/ttk/latest/arm-template-toolkit.zip'
        $DestinationDirectory = $TestDirectory + (Split-Path -Path $ARMTTKUrl -Leaf)
        try {
            Write-Build Yellow "Downloading to: $DestinationDirectory"
            Invoke-RestMethod -Uri $ARMTTKUrl -OutFile $DestinationDirectory
        }
        catch {
            Throw "Exception occured: $_"
        }

        Write-Build Yellow "Extracting ARM Test Toolkit to: $TestDirectory"
        Expand-Archive -Path $DestinationDirectory -DestinationPath $TestDirectory
        $ModulePath = (Get-ChildItem -Path $TestDirectory -Filter arm-ttk.psm1 -Recurse).FullName
    }

    Import-Module $ModulePath

    foreach ($Package in $Packages) {
        Write-Build Yellow "Testing against: $Package"
        $Result = Test-AzTemplate -TemplatePath $Package -ErrorAction SilentlyContinue
        Write-Output $Result.Name
    }
}


task PublishBicep {
    $Script:Templates = [System.Collections.ArrayList]@()

    $Packages = (Get-ChildItem -Path $BuildDirectory -Filter *.json | Where-Object {$_.Name -like "module.*"}).FullName
    Write-Build Yellow "Retrieved number of packages to publish: $($Packages.Count)"

    foreach ($Package in $Packages) {
        Write-Build Yellow "Retrieving content from: $Package"
        $JSONContent = Get-Content $Package | ConvertFrom-Json
        if ($JSONContent.variables.templateSpecName) {
            $TemplateObject = [PSCustomObject]@{
                TemplateFileName = $Package
                TemplateSpecName = $JSONContent.variables.templateSpecName
                Version          = $JSONContent.variables.version
                Description      = $JSONContent.variables.releasenotes
            }
            Write-Build Yellow $TemplateObject
            $null = $Templates.Add($TemplateObject)
        }
    }
    $Templates.ToArray() | Foreach-Object {
        $_
        $TemplateSpecName = $_.TemplateSpecName
        Write-Build Yellow $_.TemplateSpecName
        try {
            $Params = @{
                ResourceGroupName = $ResourceGroupName
                Name = $TemplateSpecName
                ErrorAction = 'Stop'
            }
            $ExistingSpec = Get-AzTemplateSpec @Params
            $CurrentVersion = $ExistingSpec.Versions | Sort-Object name | Select-Object -Last 1 -ExpandProperty Name
        } catch {
            Write-Build Yellow "No version exist for template: $TemplateSpecName"
        }

        if ($_.Version -gt $CurrentVersion) {
            Write-Build Yellow "Template version is newer than in Azure, deploying..."
            try {
                $SpecParameters = @{
                    Name                = $TemplateSpecName
                    ResourceGroupName   = $ResourceGroupName
                    Location            = $Location
                    TemplateFile        = $_.TemplateFileName
                    Version             = $_.Version
                    VersionDescription  = $_.Description         
                }
                $null = New-AzTemplateSpec @SpecParameters

                Write-Build Yellow "Setting new version number"
                $Version = $_.Version
            } catch {
                $Version = $CurrentVersion
                Write-Error "Something went wrong with deploying $TemplateSpecName : $_"
            }
        } else {
            Write-Build Yellow "$TemplateSpecName template is up to date"
            Write-Build Yellow "Keeping current version number"
            $Version = $CurrentVersion
        }
    }
}

task GenerateDocs {
    Write-Build Yellow ("TemplateFolder       : $($BuildDirectory)")
    Write-Build Yellow ("OutputFolder         : $($DocsDirectory)")
    Write-Build Yellow ("ExcludeFolders       : $($ExcludeFolders)")
    Write-Build Yellow ("KeepStructure        : $($KeepStructure)")
    Write-Build Yellow ("IncludeWikiTOC       : $($IncludeWikiTOC)")

    $templateNameSuffix = ".md"
    $option = [System.StringSplitOptions]::RemoveEmptyEntries
    $exclude = $ExcludeFolders.Split(',', $option)

    try {
        Write-Build Yellow "Starting documentation generation for folder $($BuildDirectory)"

        if (!(Test-Path $DocsDirectory)) {
            Write-Build Yellow "Output path does not exists creating the folder: $($DocsDirectory)"
            New-Item -ItemType Directory -Force -Path $DocsDirectory
        }

        # Get the scripts from the folder
        $templates = Get-Childitem $BuildDirectory -Filter "*.json" -Recurse -Exclude "*parameters.json","*descriptions.json","*parameters.local.json"

        foreach ($template in $templates) {
            if (!$exclude.Contains($template.Directory.Name)) {
                Write-Build Yellow "Documenting file: $($template.FullName)"

                if ($KeepStructure) {
                    if ($template.DirectoryName -ne $TemplateFolder) {
                        $newfolder = $DocsDirectory + "/" + $template.Directory.Name
                        if (!(Test-Path $newfolder)) {
                            Write-Build Yellow "Output folder for item does not exists creating the folder: $($newfolder)"
                            New-Item -Path $DocsDirectory -Name $template.Directory.Name -ItemType "directory"
                        }
                    }
                } else {
                    $newfolder = $DocsDirectory
                }

                $templateContent = Get-Content $template.FullName -Raw -ErrorAction Stop
                $templateObject = ConvertFrom-Json $templateContent -ErrorAction Stop

                if (!$templateObject) {
                    Write-Error -Message ("ARM Template file is not a valid json, please review the template")
                } else {
                    $outputFile = ("$($newfolder)/$($template.BaseName)$($templateNameSuffix)")
                    Out-File -FilePath $outputFile
                    if ($IncludeWikiTOC) {
                        ("[[_TOC_]]`n") | Out-File -FilePath $outputFile
                        "`n" | Out-File -FilePath $outputFile -Append
                    }

                    if ((($templateObject | get-member).name) -match "metadata") {
                        if ((($templateObject.metadata | get-member).name) -match "Description") {
                            Write-Build Yellow "Description found. Adding to parent page and top of the arm-template specific page"
                            ("## Description") | Out-File -FilePath $outputFile -Append
                            $templateObject.metadata.Description | Out-File -FilePath $outputFile -Append
                        }

                        ("## Information") | Out-File -FilePath $outputFile -Append
                        $metadataProperties = $templateObject.metadata | get-member | where-object MemberType -eq NoteProperty
                        foreach ($metadata in $metadataProperties.Name) {
                            switch ($metadata) {
                                "Description" {
                                    Write-Build Yellow ("already processed the description. skipping")
                                }
                                Default {
                                    ("`n") | Out-File -FilePath $outputFile -Append
                                    ("**$($metadata):** $($templateObject.metadata.$metadata)") | Out-File -FilePath $outputFile -Append
                                }
                            }
                        }
                    }
                    
                    ("## Parameters") | Out-File -FilePath $outputFile -Append
                    # Create a Parameter List Table
                    $parameterHeader = "| Parameter Name | Parameter Type |Parameter Description | Parameter DefaultValue | Parameter AllowedValues |"
                    $parameterHeaderDivider = "| --- | --- | --- | --- | --- | "
                    $parameterRow = " | {0}| {1} | {2} | {3} | {4} |"

                    $StringBuilderParameter = @()
                    $StringBuilderParameter += $parameterHeader
                    $StringBuilderParameter += $parameterHeaderDivider

                    $StringBuilderParameter += $templateObject.parameters | get-member -MemberType NoteProperty | ForEach-Object { $parameterRow -f $_.Name , $templateObject.parameters.($_.Name).type , $templateObject.parameters.($_.Name).metadata.description, $templateObject.parameters.($_.Name).defaultValue , (($templateObject.parameters.($_.Name).allowedValues) -join ',' )}
                    $StringBuilderParameter | Out-File -FilePath $outputFile -Append

                    ("## Resources") | Out-File -FilePath $outputFile -Append
                    # Create a Resource List Table
                    $resourceHeader = "| Resource Name | Resource Type | Resource Comment |"
                    $resourceHeaderDivider = "| --- | --- | --- | "
                    $resourceRow = " | {0}| {1} | {2} | "

                    $StringBuilderResource = @()
                    $StringBuilderResource += $resourceHeader
                    $StringBuilderResource += $resourceHeaderDivider

                    $StringBuilderResource += $templateObject.resources | ForEach-Object { $resourceRow -f $_.Name, $_.Type, $_.Comments }
                    $StringBuilderResource | Out-File -FilePath $outputFile -Append


                    if ((($templateObject | get-member).name) -match "outputs") {
                        Write-Build Yellow "Output objects found."
                        if (Get-Member -InputObject $templateObject.outputs -MemberType 'NoteProperty') {
                            ("## Outputs") | Out-File -FilePath $outputFile -Append
                            # Create an Output List Table
                            $outputHeader = "| Output Name | Output Type | Output Value |"
                            $outputHeaderDivider = "| --- | --- | --- |  "
                            $outputRow = " | {0}| {1} | {2} | "

                            $StringBuilderOutput = @()
                            $StringBuilderOutput += $outputHeader
                            $StringBuilderOutput += $outputHeaderDivider

                            $StringBuilderOutput += $templateObject.outputs | get-member -MemberType NoteProperty | ForEach-Object { $outputRow -f $_.Name , $templateObject.outputs.($_.Name).type , $templateObject.outputs.($_.Name).value }
                            $StringBuilderOutput | Out-File -FilePath $outputFile -Append
                        }
                    } else {
                        Write-Build Yellow "This file does not contain outputs"
                    }
                }
            }
        }
    } catch {
        Write-Error "Something went wrong while generating the output documentation: $_"
    }
}

task . Clean, BuildBicep