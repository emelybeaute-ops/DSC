$temp = Join-Path $env:TEMP 'vs_buildtools.exe'
Write-Host "Downloading Visual Studio Build Tools installer to: $temp"
Invoke-WebRequest 'https://aka.ms/vs/17/release/vs_BuildTools.exe' -OutFile $temp -UseBasicParsing
Write-Host 'Launching installer (will request elevation) to add C++ workload...'
Start-Process -FilePath $temp -ArgumentList '--passive', '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includerecommended' -Wait
Write-Host 'Installer finished (check installer UI/exit code).'
