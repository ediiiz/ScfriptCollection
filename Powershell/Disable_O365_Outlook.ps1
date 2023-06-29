Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover\RedirectServers" -Force -Verbose | ForEach-Object {New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover" -Name 'ExcludeExplicitO365Endpoint' -Value 1 -PropertyType DWord -Verbose}
