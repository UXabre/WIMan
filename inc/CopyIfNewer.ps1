function CopyIfNewer($source_file, $destination_file) {
    Log "INFO" "Started Copy-If-Newer $source_file => $destination_file"

    Log "DEBUG" "Creating destination folder $(([System.IO.FileInfo]$destination_file).Directory.FullName) if needed..."
    New-Item -Force -ItemType directory -Path ([System.IO.FileInfo]$destination_file).Directory.FullName | Out-Null

    Log "DEBUG" "Comparing old $source_file (LW: $(([System.IO.FileInfo]$source_file).LastWriteTime) Size: $(([System.IO.FileInfo]$source_file).Length -ne ([System.IO.FileInfo]$destination_file).Length)) with new $destination_file (LW: $(([System.IO.FileInfo]$destination_file).LastWriteTime) Size: $(([System.IO.FileInfo]$source_file).Length -ne ([System.IO.FileInfo]$destination_file).Length))"
    if ( !(Test-Path $destination_file -PathType Leaf) -or
            (( ([System.IO.FileInfo]$source_file).LastWriteTime -gt ([System.IO.FileInfo]$destination_file).LastWriteTime ) -and
            ( ([System.IO.FileInfo]$source_file).Length -ne ([System.IO.FileInfo]$destination_file).Length )
            )
        ) {
        Log "INFO" "Overwriting $destination_file ..."
	    Copy-Item $source_file -Destination $destination_file | Out-Null
    }

    Log "INFO" "Ended Copy-If-Newer"
}
