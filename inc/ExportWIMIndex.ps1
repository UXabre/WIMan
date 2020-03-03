function ExportWIMIndex($wimFile, $exportedWimFile, $index) {
    Log "INFO" "Export WIM File $wimFile, Index $index to $exportedWimFile"
    Export-WindowsImage -SourceImagePath "$wimFile" -SourceIndex $index -DestinationImagePath "$exportedWimFile" -CompressionType "max" -SetBootable -ErrorAction SilentlyContinue
    if ($? -ne 0) {
        Log "INFO" "Successfully exported WIM File $wimFile, Index $index to $exportedWimFile [$((Get-Item $exportedWimFile).length) bytes]"
        return $true
    } else {
        Log "ERROR" "Failed to export WIM File $wimFile, Index $index to $exportedWimFile"
        return $false
    }
}