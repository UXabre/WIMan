param([string]$sourcesfolder = "$pwd\sources\", [string]$outputfolder = "$pwd\finalized\", [string]$tempfolder = "$pwd\.tmp\", [int]$Optimization = 1)
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Includes
. ".\inc\Log.ps1"
. ".\inc\AddDriversToWIM.ps1"
. ".\inc\AddUpdatesToWIM.ps1"
. ".\inc\ConfigureWinPEConsole.ps1"
. ".\inc\ConvertArchitectureIdToString.ps1"
. ".\inc\CopyBootFiles.ps1"
. ".\inc\CopyIfNewer.ps1"
. ".\inc\DetectWindowsName.ps1"
. ".\inc\ExportWIMIndex.ps1"
. ".\inc\ExtractISO.ps1"
. ".\inc\ExtractWIM.ps1"
. ".\inc\ExtractXMLFromWIM.ps1"
. ".\inc\FinishWIM.ps1"
. ".\inc\GetLatestWinPEImages.ps1"
. ".\inc\InstallChoco.ps1"
. ".\inc\InstallWAIK.ps1"
. ".\inc\OptimizeWIM.ps1"
. ".\inc\PrepareInstallWIM.ps1"
. ".\inc\PrepareWIM.ps1"
. ".\inc\PrepareWinPEWIM.ps1"
. ".\inc\SetWinPETargetPath.ps1"

# MAIN starts here!
$isAdmin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin -eq $true) {
    DetectAndInstallWAIK

    $folder = New-Item -Force -ItemType directory -Path $tempfolder
    $folder.Attributes += 'HIDDEN'

    $list_isos = Get-ChildItem -Path "$sourcesfolder\*\*\*.iso"

    foreach($iso in $list_isos){
        Write-Host "Building media for " $iso.Directory.Name "[" $iso.Directory.Parent.Name "]"
        ExtractISO $iso $tempfolder $overwrite

        DetectWindowsName $iso

        PrepareWinPEWIM $iso $outputfolder
        PrepareInstallWIM $iso $outputfolder

        Write-Host "`tCopying boot files... " -NoNewline -ForegroundColor White
        CopyBootFiles $iso $outputfolder
        Write-Host "OK" -ForegroundColor Green
    }

    Write-Host "All Done!"
} else {
    Write-Host -ForegroundColor red -BackgroundColor Black "╔════════════════════════════════════════════════════════════╗"
    Write-Host -ForegroundColor red -BackgroundColor Black "║                Not running as administrator                ║"
    Write-Host -ForegroundColor red -BackgroundColor Black "╟────────────────────────────────────────────────────────────╢"
    Write-Host -ForegroundColor red -BackgroundColor Black "║ please run this script in an elevated powershell instance! ║"
    Write-Host -ForegroundColor red -BackgroundColor Black "╚════════════════════════════════════════════════════════════╝"
}