[CmdletBinding()]
param (
    $operation = 'disable'
)

$currentScriptPath = $MyInvocation.MyCommand.Definition
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$needsRestart = $false

if (-not (Test-Path -Path "$env:PROGRAMFILES\Riot Vanguard")) {
    Write-Error "Error: Vanguard not in default location or not installed."
    Read-Host -Prompt "Press Enter to exit"
    exit
}

if (-not $isAdmin) {
    Write-Host "Elevating script to admin..."
    if (Get-Command -Name "gsudo" -ErrorAction SilentlyContinue) {
        gsudo $currentScriptPath -operation $operation
        exit
    } else {
        Write-Host "'gsudo' not found, using native elevation..."
        $adminArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$currentScriptPath`" -operation $operation"
        $output = Start-Process -FilePath "powershell" -ArgumentList $adminArgs -Verb RunAs -Wait | Out-String
        Write-Host $output
        exit
    }
}

Write-Host "Vanguard Control"
Write-Host "----------------"

try {
    Write-Host "Operation: $operation"

    $vgcService = Get-Service -Name "vgc"
    $vgkService = Get-Service -Name "vgk"

    switch ($operation) {
        'enable' {
            Write-Host "Attempting to enable VGC & VGK..."

            if (($vgcService.StartType -eq "Manual") -and ( $vgkService.StartType -eq "System")) {
                Write-Host "VGC & VGK already enabled"
            } else {
                $vgcService | Set-Service -StartupType "Manual"

                $command = { sc.exe config vgk start= system }
                . $command | Out-Null
                $needsRestart = $true

                Write-Host "VGC & VGK enabled"
            }
        }
        'disable' {
            Write-Host "Attempting to disable VGC & VGK..."

            if (($vgcService.StartType -eq "Disabled") -and ($vgkService.StartType -eq "Disabled")) {
                Write-Host "VGC & VGK already disabled"
            } else {
                if (($vgcService.StartType -eq "Manual") -and ($vgkService.StartType -eq "System")) {
                    $vgcService | Set-Service -StartupType "Disabled"
                    Stop-Service $vgcService -ErrorAction SilentlyContinue

                    $vgkService | Set-Service -StartupType "Disabled"
                    Stop-Service $vgkService -ErrorAction SilentlyContinue

                    Write-Host "VGC & VGK disabled"

                    Remove-Item -Path "$env:PROGRAMFILES\Riot Vanguard\Logs" -Force -Recurse -ErrorAction SilentlyContinue

                    if (-not (Test-Path -Path "$env:PROGRAMFILES\Riot Vanguard\Logs")) {
                        Write-Host "Logs deleted!"
                    } else {
                        Write-Host "Error: Failed to delete logs."
                    }
                }
            }
        }
        'vgk_status' {
            Get-Service -Name "vgk" | Select-Object -Property *
        }
        default {
            Write-Host "Error: Invalid operation '$operation'. Valid options are 'enable', 'disable' and 'vgk_status'."
        }
    }
} catch {
    Write-Error "Error: $_"
}

Get-Process -Name "vgtray" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

if ($needsRestart) {
    Write-Host "To load driver (initiate rootkit), restart is required."
    Restart-Computer -Confirm
}
