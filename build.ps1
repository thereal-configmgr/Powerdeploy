properties {
  $buildFolder = Join-Path $PSScriptRoot '_build'
  $sourceFolder = Join-Path $PSScriptRoot 'Source'
  $version = git describe --tags --always --long
}

task default -depends Build
task Build -depends Clean, Test, Package
task Package -depends Version, Squirt, Unversion

task Squirt {
    Copy-Item $sourceFolder\* $buildFolder -Recurse -Exclude *.Tests.ps1,.git
}

task Test { 
    exec {."$PSScriptRoot\pester\bin\pester.bat" "$sourceFolder"}
}

task Version {
    $v = git describe --abbrev=0 --tags
    $changeset=(git log -1 $($v + '..') --pretty=format:%H)
    (Get-Content "$sourceFolder\PowerDeploy.psm1") `
        | % {$_ -replace "\`$version\`$", "$version" } `
        | % {$_ -replace "\`$sha\`$", "$changeset" } `
        | Set-Content "$sourceFolder\PowerDeploy.psm1"
}

task Unversion {
    $v = git describe --abbrev=0 --tags
    $changeset=(git log -1 $($v + '..') --pretty=format:%H)
    (Get-Content "$sourceFolder\PowerDeploy.psm1") `
      | % {$_ -replace "$version", "`$version`$" } `
      | % {$_ -replace "$changeset", "`$sha`$" } `
      | Set-Content "$sourceFolder\PowerDeploy.psm1"
}

task Clean { 
    if (Test-Path $buildFolder) {
        Remove-Item $buildFolder -Recurse -Force
    }
    New-Item $buildFolder -ItemType Directory | Out-Null
}

task ? -Description "Helper to display task info" {
    Write-Documentation
}