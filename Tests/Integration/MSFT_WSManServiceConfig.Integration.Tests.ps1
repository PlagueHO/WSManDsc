$script:DSCModuleName   = 'WSManDsc'
$script:DSCResourceName = 'MSFT_WSManServiceConfig'

#region HEADER
# Integration Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion HEADER

# Load the parameter List from the data file
$parameterList = Import-LocalizedData `
    -BaseDirectory "$moduleRoot\DscResources\$($script:DSCResourceName)\" `
    -FileName 'MSFT_WSManServiceConfig.parameterlist.psd1'

# Backup the existing settings
$CurrentWsManServiceConfig = [PSObject] @{}
foreach ($parameter in ($parameterList | Where-Object -Property IntTest -eq $True))
{
    $ParameterPath = Join-Path `
        -Path 'WSMan:\Localhost\Service\' `
        -ChildPath $parameter.Path
    $CurrentWsManServiceConfig.$($Parameter.Name) = (Get-Item -Path $ParameterPath).Value
} # foreach

# Using try/finally to always cleanup even if something awful happens.
try
{
    # Make sure WS-Man is enabled
    if (-not (Get-PSPRovider -PSProvider WSMan -ErrorAction SilentlyContinue))
    {
        $null = Enable-PSRemoting `
            -SkipNetworkProfileCheck `
            -Force `
            -ErrorAction Stop
    } # if

    # Set the Service Config to default settings
    foreach ($parameter in ($parameterList | Where-Object -Property IntTest -eq $True))
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path
        Set-Item -Path $ParameterPath -Value $($parameter.Default) -Force
    } # foreach

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestEnvironment.WorkingFolder
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            # Get the Rule details
            foreach ($parameter in ($parameterList | Where-Object -Property IntTest -eq $True))
            {
                $ParameterPath = Join-Path `
                    -Path 'WSMan:\Localhost\Service\' `
                    -ChildPath $parameter.Path
                (Get-Item -Path $ParameterPath).Value | Should Be $WSManServiceConfigNew.$($parameter.Name)
            } # foreach
        }
    }
    #endregion
}
finally
{
    # Clean up by restoring all parameters
    foreach ($parameter in ($parameterList | Where-Object -Property IntTest -eq $True))
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Service\' `
            -ChildPath $parameter.Path
        Set-Item -Path $ParameterPath -Value $CurrentWsManServiceConfig.$($parameter.Name) -Force
    } # foreach

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
