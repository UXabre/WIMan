$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin -eq $true) {
    $Drive = Read-Host "Enter the drive-letter you which to capture"
    $Name = Read-Host "Provide the name for the image (Will be used as title regardless of filename)"

    write-host "Creating directory to store captured images"
    new-item -Path "Captured_Images" -ItemType Directory
    write-host "Created"

    DISM /image:"${Drive}:\" /optimize-image /boot
    New-WindowsImage -ImagePath "Captured_Images\$Name.wim" -CapturePath "${Drive}:\" -Name:"$Name" -Description:"$Name"

    Write-Host Done
} else {
    Write-Host -ForegroundColor red -BackgroundColor Black "please run this script in an elevated powershell instance!"
}