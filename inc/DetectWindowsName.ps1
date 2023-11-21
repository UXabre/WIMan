function DetectWindowsName($iso) {
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    Log "DEBUG" "Arch: $architecture"
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    Log "DEBUG" "Sourcefolder: $sourcefolder"
    $installwim = $tempfolder + $sourcefolder + '\sources\install.wim'
    Log "DEBUG" "Install.wim location: $installwim"

    $metaData = ExtractXMLFromWIM $installwim
    [array]$wimImages = $metaData.WIM.IMAGE
    $windowsBase = $wimImages[0].NAME.Substring(0, $wimImages[0].NAME.LastIndexOf(' '))
    Log "INFO" "Detected: $windowsBase"
    Write-Host "`tDetected " -NoNewLine
    Write-Host "$windowsBase" -ForegroundColor Yellow
}