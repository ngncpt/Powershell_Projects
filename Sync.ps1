#Variable part
param (
    [string]$SourceDirectory,
    [string]$ReplicaDirectory,
    [string]$LogFile
)
function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

# Function to log operations and output them to the console.
function LogWrite {
    Param ([string]$logstring)
    Add-Content $LogFile -Value $(Get-TimeStamp),$logstring
    Write-Output $(Get-TimeStamp) $logstring
}
# Synchronizes content from the source to the replica directory.

function Sync-Folder {
    try {
        # Ensure the replica directory is present.
        if (-not (Test-Path -Path $ReplicaDirectory)) {
            New-Item -ItemType Directory -Path $ReplicaDirectory | Out-Null
            LogWrite "Created replica directory: $ReplicaDirectory"
        }

       # Gather items from both the source and replica directories.
        $sourceItems = Get-ChildItem -Path $SourceDirectory -Recurse
        $replicaItems = Get-ChildItem -Path $ReplicaDirectory -Recurse

        # Remove items from the replica that are no longer in the source.
        foreach ($item in $replicaItems) {
            $sourcePath = $item.FullName.Replace($ReplicaDirectory, $SourceDirectory)
            if (-not (Test-Path -Path $sourcePath)) {
                Remove-Item -Path $item.FullName -Force
                LogWrite "Removed: $($item.FullName)"
            }
        }

        # Copy or update items from the source to the replica.
        foreach ($item in $sourceItems) {
            $replicaPath = $item.FullName.Replace($SourceDirectory, $ReplicaDirectory)
            if (-not (Test-Path -Path $replicaPath) -or (Get-Item $replicaPath).LastWriteTime -lt $item.LastWriteTime) {
                $itemDir = [System.IO.Path]::GetDirectoryName($replicaPath)
                if (-not (Test-Path -Path $itemDir)) {
                    New-Item -ItemType Directory -Path $itemDir | Out-Null
                    LogWrite "Created directory: $itemDir"
                }
                Copy-Item -Path $item.FullName -Destination $replicaPath -Force
                LogWrite "Copied: $($item.FullName) to $($replicaPath)"
            }
        }

        LogWrite "Synchronization complete."
    } catch {
        LogWrite "Error: $_"
    }
}

# Start the synchronization process
Sync-Folder