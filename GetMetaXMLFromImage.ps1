param ([string]$image)

. ".\inc\ExtractXMLFromWIM.ps1"

$image = ([System.IO.FileInfo]$image)
$wimFile = $image
if ($image.EndsWith(".iso") -eq $true) {
    $mount_params = @{ImagePath = $image; PassThru = $true; ErrorAction = "Ignore"}
    $mount = Mount-DiskImage @mount_params
    $volume = Get-DiskImage -ImagePath $image | Get-Volume
    $wimFile = $volume.DriveLetter + ":\sources\install.wim"
}

(ExtractXMLFromWIM $wimFile).WIM.IMAGE

if ($image.EndsWith(".iso") -eq $true) {
    Dismount-DiskImage -ImagePath $image | Out-Null
}