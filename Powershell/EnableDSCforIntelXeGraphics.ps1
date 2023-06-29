$deviceName = "Intel(R) Iris(R) Xe Graphics"

function Get-DriverKey {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceName
    )

    $driverKey = Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PNPEntity | Where-Object { $_.Description -like $DeviceName } | Select-Object -ExpandProperty ClassGuid

    if (-not $driverKey) {
        throw "Failed to retrieve the Driverkey for the specified device."
    }

    return $driverKey
}

function Test-RegistryValue {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath,
        [Parameter(Mandatory=$true)]
        [string]$ValueName
    )

    try {
        $valueExists = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-RegistryDWORDValue {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath,
        [Parameter(Mandatory=$true)]
        [string]$ValueName
    )

    try {
        $value = Get-ItemPropertyValue -Path $RegistryPath -Name $ValueName -ErrorAction Stop
        return $value
    }
    catch {
        throw "Failed to retrieve the value of '$ValueName' in the specified registry path."
    }
}

function Set-RegistryDWORDValue {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath,
        [Parameter(Mandatory=$true)]
        [string]$ValueName,
        [Parameter(Mandatory=$true)]
        [int]$Value
    )

    try {
        Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $Value -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Failed to set the value of '$ValueName' in the specified registry path."
    }
}

try {
    $driverKey = Get-DriverKey -DeviceName $deviceName
    $registryPath = "HKLM:\SYSTEM\ControlSet001\Control\Class\$driverKey\0000"

    if (Test-RegistryValue -RegistryPath $registryPath -ValueName "DpMstDscDisable") {
        $currentValue = Get-RegistryDWORDValue -RegistryPath $registryPath -ValueName "DpMstDscDisable"

        if ($currentValue -eq 0) {
            Write-Host "The value is already set to 0."
        }
        else {
            Set-RegistryDWORDValue -RegistryPath $registryPath -ValueName "DpMstDscDisable" -Value 0
            Write-Host "The value has been changed to 0."
        }
    }
    else {
        Write-Host "The 'DpMstDscDisable' value does not exist in the specified registry path."
    }
}
catch {
    Write-Host "Error: $_"
}
