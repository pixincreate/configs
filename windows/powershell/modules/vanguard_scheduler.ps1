[CmdletBinding()]
param (
    [string]$action = 'help'  # Default action
)

function Install-ScheduledTask {
    param (
        [string]$path  # Optional parameter for the path
    )

    if (-not $path) {
        # Set paths depending on the version of PowerShell
        if ($PSVersionTable.PSEdition -eq "Core") {
            $path = "$env:userprofile\Documents\PowerShell\Modules"
        } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $path = "$env:userprofile\Documents\WindowsPowerShell\Modules"
        }
    }

    Write-Host "Installing Scheduled Task..."

    # Create a new task action
    $taskName = 'VanguardController'
    $taskDescription = 'Control Vanguard Execution'
    $taskAction = New-ScheduledTaskAction `
        -Execute 'PowerShell' `
        -Argument "$path\vanguard.ps1 disable -isScheduledTask" `
        -WorkingDirectory $path
    $taskSettings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
        -Priority 7
    $taskTrigger = @(
        $(New-ScheduledTaskTrigger -Daily -At 8PM),
        $(New-ScheduledTaskTrigger -AtLogon)
    )

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $taskAction `
        -Trigger $taskTrigger `
        -Description $taskDescription `
        -Settings $taskSettings
}

function Backup-SchedulerTask {
    Get-ScheduledTask -TaskName 'VanguardController' | `
        Export-Clixml "C:\Users\${env:UserName}\Documents\PowerShell\Modules\VanguardController.xml"
}

function Restore-SchedulerTask {
    $task = Import-Clixml "C:\Users\${env:UserName}\Documents\PowerShell\Modules\VanguardController.xml"
    Register-ScheduledTask -InputObject $task
}

function Unregister-SchedulerTask {
    Unregister-ScheduledTask -TaskName 'VanguardController' -Confirm:$false
}

function Get-EventLogs {
    param(
        [Parameter(Mandatory = $true)]
        [int]$number
    )
    Get-WinEvent -LogName application -MaxEvents $number
}

function help {
    Write-Host "Scheduler Module"
    Write-Host "----------------"
    Write-Host "Install-ScheduledTask: Installs a scheduled task to disable Vanguard at 8PM and at logon."
    Write-Host "Backup-SchedulerTask: Backs up the VanguardController scheduled task as `xml` in Module directory."
    Write-Host "Restore-SchedulerTask: Restores the VanguardController scheduled task."
    Write-Host "Unregister-SchedulerTask: Unregisters the VanguardController scheduled task."
    Write-Host "Get-EventLogs: Get the last n event logs. Usage: Get-EventLogs <number>"
    Write-Host "help: Display this help message."
}

function main {
    Write-Host "Scheduler Module"
    Write-Host "----------------"
    Write-Host "Operation: $action"

    switch ($action) {
        'Install-ScheduledTask' {
            Install-ScheduledTask -path $path
        }
        'Backup-SchedulerTask' {
            Backup-SchedulerTask
        }
        'Restore-SchedulerTask' {
            Restore-SchedulerTask
        }
        'Unregister-SchedulerTask' {
            Unregister-SchedulerTask
        }
        'Get-EventLogs' {
            Get-EventLogs
        }
        'help' {
            help
        }
        default {
            Write-Host "Invalid action. Use 'help' to see available actions."
        }
    }
}

main
