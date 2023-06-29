# Define the source file and destination path
$sourcePath = "C:\temp"
$destinationPath = "$env:TEMP\EndpointProductRemoval.exe"

# Copy the newest .exe file to the temp folder
$latestFile = Get-ChildItem -Path $sourcePath -Filter "*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$latestFilePath = Join-Path -Path $sourcePath -ChildPath $latestFile.Name

# Execute the exe with specified arguments
$arguments = "--accepteula --ALL --noreboot --notelemetry"
Start-Process -FilePath $destinationPath -ArgumentList $arguments -Wait

# Check the exit code and provide an explanation
$exitCode = $LASTEXITCODE

switch ($exitCode) {
    0 { Write-Host "Successful removal" }
    1010 { Write-Host "Invalid command line" }
    5030 { Write-Host "Conflicting product(s) found" }
    -1 { Write-Host "Error encountered while running EPR" }
    1 { Write-Host "Likely a successful removal" }
    default { Write-Host "Unknown exit code: $exitCode" }
}

Get-ChildItem -Filter "EndpointProductRemoval*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty VersionInfo -First 1 | Select-Object -ExpandProperty FileName | ForEach-Object {Start-Process -FilePath $_ -ArgumentList "--accepteula --ALL --noreboot --notelemetry" -Wait -passthru | Select-Object -ExpandProperty ExitCode} 


$path = Get-ChildItem -Filter "EndpointProductRemoval*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty VersionInfo -First 1 | Select-Object -ExpandProperty FileName
$proc = Start-Process -FilePath $path -ArgumentList "--accepteula --ALL --noreboot --notelemetry" -Wait -passthru
switch ($proc.ExitCode) {
    0 { Write-Host "Successful removal" }
    1010 { Write-Host "Invalid command line" }
    5030 { Write-Host "Conflicting product(s) found" }
    -1 { Write-Host "Error encountered while running EPR" }
    1 { Write-Host "Likely a successful removal" }
    default { Write-Host "Unknown exit code: $exitCode" }
}
