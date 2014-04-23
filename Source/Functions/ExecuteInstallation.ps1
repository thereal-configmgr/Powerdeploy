function ExecuteInstallation (
    $PackageName, 
    $PackageVersion, 
    $EnvironmentName, 
    $DeployedFolderPath,
    $DeploymentSourcePath,
    [Hashtable] $Settings) { 

    Import-Module "$PSScriptRoot\..\Helpers\Installer.psm1" -Verbose:$false

    # Set up the context to transition to the module.
    # It may seem odd here that we are importing a module and setting up a context
    # to run conventions in, rather than just using include functions like we do
    # for all of the steps that lead up to here, but ExecuteInstallation is really
    # the transition point between the "internal" side of Powerdeploy, and the
    # "consumable" side that is exposed to conventions and deployment packages.
    # For this reason, we don't want them to rely on "internals", but rather on
    # the installation module with it's published commandlets, etc.

    $context = @{
        PackageName = $PackageName
        PackageVersion = $PackageVersion
        DeployedFolderPath = $DeployedFolderPath
        EnvironmentName = $EnvironmentName
        Variables = $Settings
    }

    Set-DeploymentContext @context
    
    GetInstallationExtensions | ForEach-Object { 
        $extension = $_
        $extensionName = Split-Path (Split-Path $extension -Parent) -Leaf
        Write-Verbose "Initializing extension $extensionName..."   
        Invoke-Expression $extension
    }

    $initializationScriptPath = "$DeployedFolderPath\deploy\Initialize.ps1"
    if (Test-Path $initializationScriptPath) {
        Write-Verbose "An initialization script was found for the package and is being run..."
        & $initializationScriptPath
    }

    Write-Verbose "Executing pre-install scripts..."
    Get-RegisteredDeploymentScript -Pre -Phase Install | Invoke-RegisteredDeploymentScript

    get-command -module installer | write-host

    Write-Verbose "Executing post-install scripts..."
    Get-RegisteredDeploymentScript -Post -Phase Install | Invoke-RegisteredDeploymentScript

    Write-Verbose 'Installation finished.'

    Write-Verbose 'Unloading installation module...'
    Remove-Module Installer -Verbose:$false -ErrorAction SilentlyContinue
}

function GetInstallationExtensions() {
    Resolve-Path (Join-Path (GetInstallationExtensionRoot) "*\initialize.ps1")
}

function GetInstallationExtensionRoot() {
    Write-Verbose "Locating extensions in $PSScriptRoot\..\Extensions"
    "$PSScriptRoot\..\Extensions"
}
