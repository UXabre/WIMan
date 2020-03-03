function InstallWAIK() {
    Log "INFO" "Installing WAIK"
    Log "INFO" "Installing Choco if needed..."
    InstallChoco
    Log "INFO" "Installing windows-adk-winpe..."
    choco install windows-adk-winpe -y --installargs="/installPath `"$pwd\.tmp\wadk-winpe\`""

    if ($? -ne 0) {
        Log "INFO" "Successfully installed WAIK-WINPE"
        Write-Host "Successfully installed WAIK-WINPE" -ForegroundColor Green

        Log "DEBUG" "Copying WinPE WIM images to default WinPE folder"
        $wim_boot_files = Get-ChildItem -Path ".\.tmp\wadk-winpe\*\winpe.wim" -Recurse -ErrorAction SilentlyContinue
        foreach($wim_boot_file in $wim_boot_files){
            $architecture = $wim_boot_file.Directory.Parent.Name
            Log "DEBUG" "Copying $architecture WinPE to `".\winpe\images\$architecture\`""
            New-Item -Force -ItemType directory -Path ".\winpe\images\$architecture\" | Out-Null
            Move-Item "$wim_boot_file" ".\winpe\images\$architecture\boot.wim"
            if ($? -eq $true) {
                Log "DEBUG" "Successfully copied $architecture WinPE to `".\winpe\images\$architecture\`""
            } else {
                Log "ERROR" "Failed to copy $architecture WinPE to `".\winpe\images\$architecture\`""
            }
        }
    } else {
        Log "ERROR" "Failed installing WAIK-WINPE. Install it manually and copy the winpe.wim file to .\winpe."
        Write-Host "Failed installing WAIK-WINPE. Install it manually and copy the winpe.wim file to .\winpe." -ForegroundColor Red
        Exit -1
    }
}

function DetectAndInstallWAIK() {
    Log "INFO" "Detecting & Installing WAIK..."
    Log "DEBUG" "Checking if dedicated WinPE files are located in `".\winpe\images\`""
	$DedicatedWimFiles = Get-ChildItem -Recurse ".\winpe\images\*\boot.wim" -ErrorAction SilentlyContinue

	if ( ($DedicatedWimFiles | Measure-Object | ForEach-Object{$_.Count}) -gt 0 ) {
        Log "DEBUG" "Found $($DedicatedWimFiles | Measure-Object | ForEach-Object{$_.Count}) dedicated winpe.wim file(s)!"
		Write-Host "Found" ($DedicatedWimFiles | Measure-Object | ForEach-Object{$_.Count}) "dedicated winpe.wim file(s)!" -ForegroundColor White
	} else {
        $images = GetLatestWinPEImages

        if ($images.Count -gt 0) {
            Log "DEBUG" "We found one or more installations of WAIK; we'll copy the latest WinPE files from there  this will take a few moments..."
            Write-Host "We found one or more installations of WAIK; we'll copy the latest WinPE files from there, this will take a few moments..." -ForegroundColor White

            $images | % {
                $architecture = ConvertArchitectureIdToString($_.Latest.Architecture)
                New-Item -Force -ItemType directory -Path ".\winpe\images\$architecture\" | Out-Null
                Copy-Item "$($_.Latest.Path)" ".\winpe\images\$architecture\boot.wim"

                if ($? -eq $true) {
                    Log "DEBUG" "Successfully copied image $($_.Latest.Path) => `".\winpe\images\$architecture\boot.wim`""
                } else {
                    Log "ERROR" "Failed to copy image $($_.Latest.Path) => `".\winpe\images\$architecture\boot.wim`""
                }
            }
        } else {
            Log "INFO" "No dedicated winpe.wim file found  we can fetch this automatically for you but this takes a few minutes. Do you want to continue? (Y/N)"
            $install_WAIK_winpe = Read-Host "No dedicated winpe.wim file found, we can fetch this automatically for you but this takes a few minutes. `nDo you want to continue? (Y/N)"
            Log "INFO" "User answered: $install_WAIK_winpe"

            if ($install_WAIK_winpe -eq 'n') {
                Log "INFO" "Will use the embedded winpe file from windows installation media. This is a slightly larger file with additional features that you might not need or want. This is only a convenience rather than a solution!"
                Write-Host "Will use the embedded winpe file from windows installation media. This is a slightly larger file with additional features that you might not need or want. This is only a convenience rather than a solution!" -ForegroundColor White
            } else {
                InstallWAIK
            }
        }
	}
}