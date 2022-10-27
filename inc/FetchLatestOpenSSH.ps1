function DownloadLatestOpenSSHServer() {
    Write-Host "Fetching latest OpenSSH package... " -NoNewline -ForegroundColor White

    Log "DEBUG" "Create openssh folder in tmp"
    New-Item -Force -ItemType directory -Path "winpe/overlay/tools/openssh/" | Out-Null
    Log "DEBUG" "Clean openssh folder in tmp"
    Remove-Item "winpe/overlay/tools/openssh/*" -Recurse -Force | Out-Null

    Log "INFO" "Fetch list of latest OpenSSH releases from github"
    $request = Invoke-WebRequest -Uri https://github.com/PowerShell/Win32-OpenSSH/releases.atom -UseBasicParsing
    [xml]$content = $request.content
    $versions = $content.feed.entry | Sort-Object -Property title -Descending
    $latest = $versions[0].id.Split("/")[-1]

    New-Item -Path '.tmp/openssh/' -ItemType Directory
    Log "INFO" "Downloading x64 package for version $latest"
    Invoke-WebRequest -Uri https://github.com/PowerShell/Win32-OpenSSH/releases/download/$latest/OpenSSH-Win64.zip -OutFile .tmp/openssh/OpenSSH-Win64.zip
    Log "INFO" "Downloading x86 package for version $latest"
    Invoke-WebRequest -Uri https://github.com/PowerShell/Win32-OpenSSH/releases/download/$latest/OpenSSH-Win32.zip -OutFile .tmp/openssh/OpenSSH-Win32.zip
    
    Write-Host "Done" -ForegroundColor Green
}
