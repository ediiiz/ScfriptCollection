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


$proc = (Get-ChildItem -Filter "EndpointProductRemoval*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty VersionInfo -First 1 | Select-Object -ExpandProperty FileName | ForEach-Object { Start-Process -FilePath $_ -ArgumentList "--accepteula --ALL --noreboot --notelemetry" -Wait -PassThru }).ExitCode; switch ($proc) { 0 { Write-Host "Successful removal" }; 1010 { Write-Host "Invalid command line" }; 5030 { Write-Host "Conflicting product(s) found" }; -1 { Write-Host "Error encountered while running EPR" }; 1 { Write-Host "Likely a successful removal" }; default { Write-Host "Unknown exit code: $proc" } }


Start-Process -FilePath '.\EndpointProductRemoval_23.5.0.25.exe' -ArgumentList "--accepteula --REPAIR=ens --noreboot --notelemetry" -Wait -PassThru | fl
