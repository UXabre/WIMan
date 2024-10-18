function CopyProtectedFiles($source_glob, $destination_folder) {
    Log "INFO" "Started CopyProtectedFiles $source_glob => $destination_folder"
    
    $current_working_location = Get-Location
    Set-Location $source_glob
	$allFiles = Get-ChildItem -Recurse -File | % { $_ | Resolve-Path -Relative }
    Set-Location $current_working_location

    $allFiles | ForEach-Object {
        $source_file = $_.Replace(".\", "")
        $destination_file = "$destination_folder$source_file"

        if (Test-Path $destination_file -PathType Leaf) {
            $OriginalACL = Get-Acl -Path $destination_file
            $ACL = $OriginalACL
            
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users","Modify","Allow")
            $ACL.SetAccessRule($AccessRule)
            $ACL | Set-Acl -Path $destination_file
            Copy-Item $source_glob$source_file  -Destination $destination_file
            
            $OriginalACL | Set-Acl -Path $destination_file
        } else {
            Copy-Item $source_glob$source_file  -Destination $destination_file
        }
    }

    Log "INFO" "Ended CopyProtectedFiles"
}
