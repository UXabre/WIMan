. ".\inc\ExtractXMLFromWIM.ps1"
function GetLatestWinPEImages() {
    $info = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots\" -Name "KitsRoot*" -ErrorAction SilentlyContinue | Select -Property * -ExcludeProperty "PS*"

    $images = $info.PSObject.Properties | % {
        Get-ChildItem -Recurse -Include "winpe.wim" -Path $_.Value | % {
            $WIM = (ExtractXMLFromWIM $_).WIM

            @{
                Info = $WIM
                Version = "$($WIM.IMAGE.WINDOWS.VERSION.MAJOR).$($WIM.IMAGE.WINDOWS.VERSION.MINOR).$($WIM.IMAGE.WINDOWS.VERSION.BUILD)"
                Architecture = $WIM.IMAGE.WINDOWS.ARCH
                Path = $_
            }
        }
    }

    $images = $images | Group-Object {$_.Architecture} -Verbose | % {
        $Images = @($_.Group | Sort-Object {new-object System.Version($_.Version)} -Descending)
        @{
            Architecture = $_.Name
            Images = $Images
            Latest = $Images[0]
        }
    }

    return $images
}
