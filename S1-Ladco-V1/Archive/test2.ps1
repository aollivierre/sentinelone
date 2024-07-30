$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method1"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
robocopy $extractedFolder $destinationPath /E

Remove-Item -Path $tempExtractPath -Recurse -Force



$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method2"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
Move-Item -Path $extractedFolder\* -Destination $destinationPath -Force

Remove-Item -Path $tempExtractPath -Recurse -Force







$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method3"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
xcopy $extractedFolder $destinationPath /E /I /Y

Remove-Item -Path $tempExtractPath -Recurse -Force








$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method4"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
Copy-Item -Path $extractedFolder\* -Destination $destinationPath -Recurse -Container

Remove-Item -Path $tempExtractPath -Recurse -Force




$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method5"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
$shell = New-Object -ComObject shell.application
$zip = $shell.NameSpace($zipPath)
$extract = $shell.NameSpace($tempExtractPath)
$extract.CopyHere($zip.Items(), 16)
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
Copy-Item -Path $extractedFolder\* -Destination $destinationPath -Recurse -Container

Remove-Item -Path $tempExtractPath -Recurse -Force





$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method6"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
Copy-Item -Path $extractedFolder\* -Destination $destinationPath -Recurse -Container

Remove-Item -Path $tempExtractPath -Recurse -Force





$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method7"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
Get-ChildItem -Path $extractedFolder -Directory | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $destinationPath
}

Remove-Item -Path $tempExtractPath -Recurse -Force








$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method8"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
& "C:\Program Files\7-Zip\7z.exe" x $zipPath -o$tempExtractPath
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
Copy-Item -Path $extractedFolder\* -Destination $destinationPath -Recurse -Container

Remove-Item -Path $tempExtractPath -Recurse -Force







Install-Module -Name Pscx -Force -SkipPublisherCheck

$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method9"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-7Zip -ArchiveFileName $zipPath -TargetPath $tempExtractPath
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
Copy-Item -Path $extractedFolder\* -Destination $destinationPath -Recurse -Container

Remove-Item -Path $tempExtractPath -Recurse -Force








$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules\method10"

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"
$zipPath = "$env:TEMP\modules.zip"

Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
Remove-Item -Path $zipPath

$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"
Copy-Item -Path $extractedFolder\* -Destination $destinationPath -Recurse -Container

Remove-Item -Path $tempExtractPath -Recurse -Force





