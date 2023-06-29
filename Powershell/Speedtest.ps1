$downloadUrl = "http://212.183.159.230/10MB.zip"; 
$wc = New-Object System.Net.WebClient; 
$wc.Proxy = [System.Net.WebRequest]::GetSystemWebProxy(); 
$wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials; 
Measure-Command{$wc.DownloadFile($downloadUrl,"file")}|ForEach-Object{ Write-Host "Download Speed:"((Get-Item "file").Length/$_.TotalSeconds*8/1MB)"Mbps"}|ForEach-Object{Remove-Item "file"}