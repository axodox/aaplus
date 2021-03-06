Write-Host 'AA+ library build started' -ForegroundColor Green

# Init build environment
Write-Host 'Finding Visual Studio...' -ForegroundColor Magenta
$vsPath = .\vswhere.exe -latest -property installationPath
Write-Host $vsPath

Write-Host 'Importing environment variables...' -ForegroundColor Magenta
cmd.exe /c "call `"$vsPath\VC\Auxiliary\Build\vcvars64.bat`" && set > %temp%\vcvars.txt"
Get-Content "$env:temp\vcvars.txt" | Foreach-Object {
  if ($_ -match "^(.*?)=(.*)$") {
    Set-Content "env:\$($matches[1])" $matches[2]
  }
}

# Build all platforms
Write-Host 'Building library...' -ForegroundColor Magenta
$projectPath = (Get-Location).Path + "\lib\AALib.vcxproj"

$jobs = @()
$jobs += Start-Job -ScriptBlock { param($path) MSBuild.exe $path -p:Configuration=Debug -p:Platform=x86 -v:m } -ArgumentList $projectPath
$jobs += Start-Job -ScriptBlock { param($path) MSBuild.exe $path -p:Configuration=Release -p:Platform=x86 -v:m } -ArgumentList $projectPath
$jobs += Start-Job -ScriptBlock { param($path) MSBuild.exe $path -p:Configuration=Debug -p:Platform=x64 -v:m } -ArgumentList $projectPath
$jobs += Start-Job -ScriptBlock { param($path) MSBuild.exe $path -p:Configuration=Release -p:Platform=x64 -v:m } -ArgumentList $projectPath
$jobs += Start-Job -ScriptBlock { param($path) MSBuild.exe $path -p:Configuration=Debug -p:Platform=arm64 -v:m } -ArgumentList $projectPath
$jobs += Start-Job -ScriptBlock { param($path) MSBuild.exe $path -p:Configuration=Release -p:Platform=arm64 -v:m } -ArgumentList $projectPath
Wait-Job $jobs

#Package output
Write-Host 'Packaging output...' -ForegroundColor Magenta
Remove-Item ./nuget/lib -Recurse -ErrorAction Ignore
Remove-Item ./nuget/include -Recurse -ErrorAction Ignore
Remove-Item ./nuget/docs -Recurse -ErrorAction Ignore

New-Item ./nuget/lib -ItemType Directory -ErrorAction Ignore
New-Item ./nuget/include -ItemType Directory -ErrorAction Ignore

Copy-Item ./lib/bin/* ./nuget/lib -Recurse -Force
Copy-Item ./lib/*.h ./nuget/include -Force
Copy-Item ./docs ./nuget -Recurse -Force
Copy-Item ./license.txt ./nuget/license.txt -Force

.\nuget.exe pack ./nuget/AAPlus.nuspec