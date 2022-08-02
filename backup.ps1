## Root backup task
Import-Module WebAdministration
Stop-Website site.com
Stop-WebAppPool -Name site.com
Start-Sleep -Seconds 10
$file_name = 'www_' + (Get-Date -Format "yyyy-MM-dd--HH-mm-ss") + '.zip'
Compress-Archive -Path C:\inetpub\site.com\www -DestinationPath C:\inetpub\site.com\$file_name -Force
Start-Website site.com
Start-WebAppPool -Name site.com


##Enter credentials to connect to FTP server.
$FTPUsername = "ftpuser"
$FTPPwd = 'ftppass'
$Password = ConvertTo-SecureString $FTPPwd -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($FTPUsername, $Password)

#Import WinSCP module
Import-Module WinSCP

#Create WinSCP session to your FTP server. backupserver.site.com is the FTP server. 
$WinSCPSession = New-WinSCPSession -SessionOption (New-WinSCPSessionOption -HostName backupserver.site.com -Protocol Sftp -Credential $Credential -SshHostKeyFingerprint "ssh-rsa 2048 30:30:30:30:30:30:30:30:30:30:30:30:30:30:30:30")


## Copy latest database backup
$db = Get-ChildItem C:\backup-daily\site.com | sort LastWriteTime | select -last 1  # select lastes backup DB in this folder
Send-WinSCPItem -WinSCPSession $WinSCPSession -Path C:\backup-daily\site.com\$db -RemotePath '.\site.com\'

## Copy Root backup
Send-WinSCPItem -WinSCPSession $WinSCPSession -Path C:\inetpub\site.com\$file_name -RemotePath '.\site.com\'

## Remove files older than 1 month
Get-WinSCPChildItem -WinSCPSession $WinSCPSession -Path '\site.com' -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | foreach { Remove-WinSCPItem -Path ( '/site.com/' + $_ )  -Confirm:$False }

## end Session
Remove-WinSCPSession -WinSCPSession $WinSCPSession

## Remove files from local server 
Remove-Item -Path C:\inetpub\site.com\$file_name -Force
