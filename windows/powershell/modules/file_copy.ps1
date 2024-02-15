

# $sourceDirectory = ".\.config\wt\LocalState\"
# $destinationBaseDirectory = "C:\Users\PiXW\AppData\Local\Packages\"
# $pattern = "Microsoft.WindowsTerminal_*"
# $fileName = "settings.json"


param(
    [string]$sourceDirectory,
    [string]$destinationBaseDirectory,
    [string]$pattern = "*",  # Provide a default value for $pattern
    [string]$fileName
)

# Check if source and destination directories are provided
if (-not $sourceDirectory -or -not $destinationBaseDirectory -or -not $fileName) {
    Write-Host "Usage: file_copy.ps1 -sourceDirectory <SourcePath> destinationDirectory <DestinationPath> -fileName <fileName>"
    exit
}

# Validate the source directory and exit if it doesn't exist
if (-not (Test-Path $sourceDirectory -PathType Container)) {
    Write-Host "Error: Source directory '$sourceDirectory' not found."
    exit
}

# Get the correct directory containing "$pattern" in the destinationBaseDirectoryBase
$matchingDirectories = Get-ChildItem -Path $destinationBaseDirectory -Filter $pattern -Directory

if ($matchingDirectories.Count -eq 0) {
    Write-Host "Error: Matching directory not found."
} else {
    # If there are multiple matching directories, you may need to handle it accordingly.
    # For simplicity, this example takes the first matching directory.
    $matchingDirectory = $matchingDirectories[0].Name

    $destinationDirectory = Join-Path $destinationBaseDirectory $matchingDirectory
    $destinationPath = Join-Path $destinationDirectory $fileName

    # Copy the settings.json file to the destination
    Copy-Item -Path (Join-Path $sourceDirectory $fileName) -Destination $destinationPath -Force

    Write-Host "File copied successfully from $sourceDirectory to $destinationPath."
}
