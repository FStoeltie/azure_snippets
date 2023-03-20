@{
    PSDependOptions     = @{
        Target = 'CurrentUser'
    }
    InvokeBuild         = @{
        
        Version = 'Latest'
    }
    az                  = @{
        MinimumVersion = 'Latest'
    }
    PSRule              = @{
        Version = 'Latest'
    }
    'PSRule.Rules.Azure' = @{
        Version = 'Latest'
    }
    Pester               = @{
        Version = 'Latest'
    }
}