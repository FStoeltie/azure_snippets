@{
    PSDependOptions     = @{
        Target = 'CurrentUser'
    }
    InvokeBuild         = @{
        Version = '5.9.10'
    }
    az                  = @{
        MinimumVersion = 'Latest'
    }
    PSRule              = @{
        Version = '2.3.2'
    }
    'PSRule.Rules.Azure' = @{
        Version = '1.3.1'
    }
    Pester               = @{
        Version = '5.3.3'
    }
}