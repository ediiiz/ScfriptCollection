$StartDay = (Get-Date).AddDays(-7)
$BlockedEvents = @()
<# VirusTotal API Key #>
$VTApiKey = VIRUS_TOTAL_API_KEY
<# VirusTotal API Key #>

<# Proxy und TLS konfigurieren #>
$Proxy = New-object System.Net.WebProxy
$WebSession = new-object Microsoft.PowerShell.Commands.WebRequestSession
$WebSession.Proxy = $Proxy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
<# Proxy und TLS konfigurieren #>

function StartScript {
    Write-Output "-----------------------------------------------------"
    Write-Output "1. Check for blocked .EXE and compare Hash with VT"
    Write-Output "2. Display all Unique Blocked Events"
    Write-Output "3. Display all Unique Contained Events"
    Write-Output "4. Exit"
    Write-Output "-----------------------------------------------------"
    [int]$selection = Read-Host
    if ($selection -eq 1) {
        getBlockedEvents
    }
    if ($selection -eq 2) {
        getUniqueEventLogEntries
    }
    if ($Selection -eq 3) {
        getContainedEvents
    }
    if ($Selection -eq 4) {
        killProcess
        exit
    }
    StartScript
}


function killProcess {
    Get-Process -includeUsername | Where-Object { $_.UserName -match "SYSTEM" } | Where-Object { $_.ProcessName -like "*paexec*" -or $_.ProcessName -like "*powershell*" -or $_.ProcessName -like "*psexe*" } |
    ForEach-Object { Stop-Process -Id $_.Id }
}


function getBlockedEvents () {
    $idx = 1
    $BlockedEvents = Get-EventLog -LogName Application -EntryType Error -Source "McAfee Endpoint Security" -After $StartDay | 
    Select-Object Index, Timegenerated, Message | Where-Object { $_.Message -match "EventID=18060" -or $_.Message -match "EventID=37279" } | Select-Object Index, TimeGenerated, Message |
    ForEach-Object {
        New-Object PSObject -Property @{
            Index = $idx++
            Time  = $_.TimeGenerated
            Hash  = $_.Message | Select-String -Pattern "(\w:.*?.exe)" | ForEach-Object { "$($_.matches.groups[1])" } | Get-Item | Select-Object PSPath -Unique | Get-FileHash -Algorithm MD5 | Select-Object -ExpandProperty Hash
            EXE   = $_.Message | Select-String -Pattern "(\w:.*?.exe)" | ForEach-Object { "$($_.matches.groups[1])" }
        } 
    } | Select-Object Index, Time, Hash, EXE | Sort-Object Index | Sort-Object Hash -Unique | Sort-Object Time -Descending
    getVTresult($BlockedEvents)
}

function submit-VTHash($VThash) {
    $VTbody = @{resource = $VThash; apikey = $VTApiKey }
    $VTresult = Invoke-RestMethod -Method GET -Uri 'https://www.virustotal.com/vtapi/v2/file/report' -Body $VTbody -WebSession $WebSession

    return $vtResult
}

function getUniqueEventLogEntries {
    $EventlogEntries = @()
    $EventlogEntries = Get-EventLog -LogName Application -EntryType Error -Source "McAfee Endpoint Security" -After $StartDay | 
    Select-Object Index, Timegenerated, Message |
    Where-Object { $_.Message -match "EventID=37279" -or $_.Message -match "EventID=18060" } | 
    Select-Object Index, TimeGenerated, Message | 
    Sort-Object Index | 
    Sort-Object Message -Unique | 
    Sort-Object TimeGenerated -Descending
    if (($EventlogEntries | Measure-Object).Count -gt 0) {
        $EventlogEntries | Format-List
    }
    else {
        Write-Output "No blocked items found"
    }
}

function getContainedEvents {
    $ContainedEvents = @()
    $ContainedEvents = Get-EventLog -LogName Application -EntryType Error -Source "McAfee Endpoint Security" -After $StartDay | 
    Where-Object { $_.Message -match "EventID=35112" } |
    Select-Object Index, Timegenerated, Message | 
    Sort-Object Index | 
    Sort-Object Message -Unique | 
    Sort-Object TimeGenerated -Descending
    if (($ContainedEvents | Measure-Object).Count -gt 0) {
        $ContainedEvents | Format-List
    }
    else {
        Write-Output "No blocked items found"
    }
}

function getVTresult($Blocked) {
    $index = $null
    if (($Blocked | Measure-Object).Count -gt 0) {
        $Blocked | Format-List
        while ($true) {
            Write-Output "-----------------------------------------------------"
            Write-Output "Please type in the 'Index' from the displayed items"
            Write-Output "'0' = to return to the main menu"
            Write-Output "-----------------------------------------------------"
            $index = Read-Host
            if ($index -eq 0) {
                StartScript
                break
            }
            if ($index) {
                $hash = $Blocked | Where-Object { $_.Index -eq $index } | Select-Object -ExpandProperty Hash
                $VTresult = submit-VTHash($hash)
                if ($VTresult.positives -ge 1) {
                    $VTpct = (($VTresult.positives) / ($VTresult.total)) * 100
                    $VTpct = [math]::Round($VTpct, 2)
                }
                else {
                    $VTpct = 0
                }
                
                ## Display results
                [PSCustomObject]@{
                    "Blocked .exe"     = $Blocked | Where-Object { $_.Index -eq $index } | Select-Object -ExpandProperty EXE
                    "Local Block Date" = $Blocked | Where-Object { $_.Index -eq $index } | Select-Object -ExpandProperty Time
                    Hash               = $VTresult.resource
                    "VT Scan Date"     = $VTresult.scan_date
                    Positives          = $VTresult.positives
                    Total              = $VTresult.total
                    Permalink          = $VTresult.permalink
                    Percent            = $VTpct
                }
            }
            else {
                continue
            }
        }
    }
    else {
        Write-Output "No blocked items found"
    }
}


StartScript
