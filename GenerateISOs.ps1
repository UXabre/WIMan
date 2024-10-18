$path = ".tmp"
$TargetISOFile = "windowswithautopilot.iso"
$isocontents = "./iso/"

# ##Create a directory for oscdimg files
# write-host "Creating oscdimg directory"
# new-item -Path "$path\oscdimg" -ItemType Directory
# write-host "Created"

# #Set Paths for download
# $url = "https://github.com/andrew-s-taylor/oscdimg/archive/main.zip"
# $output = "$path\oscdimg.zip"

# #Download Files
# write-host "Downloading OSCDIMG Files"
# Invoke-WebRequest -Uri $url -OutFile $output -Method Get
# write-host "Download Complete"

# #Unzip them
# write-host "Unzipping Files"
# Expand-Archive $output -DestinationPath "$path\oscdimg" -Force
# Write-Host "Unzipped"

# #Remove Zip file downloaded
# write-host "Removing Zip File"
# remove-item $output -Force
# write-host "Removed"

# Create an ISO file from the installimage and new wim file
write-host "Creating ISO"
& "$path\oscdimg\oscdimg-main\oscdimg.exe" -b"iso\efi\microsoft\boot\efisys.bin" -pEF -u1 -udfver102 $isocontents $TargetISOFile
# & "$path\oscdimg\oscdimg-main\oscdimg.exe" -pEF -u1 -udfver102 $isocontents $TargetISOFile
write-host "ISO $TargetISOFile created"