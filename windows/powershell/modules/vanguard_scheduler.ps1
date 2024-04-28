function Install-ScheduledTask {
    Write-Host "Installing Scheduled Task..."
    # Create a new task action
    $taskName = 'VanguardController'
    $taskDescription = 'Control Vanguard Execution'
    $taskAction = New-ScheduledTaskAction `
        -Execute 'PowerShell' `
        -Argument "C:\Users\${env:UserName}\Documents\PowerShell\Modules\vanguard.ps1 disable -isScheduledTask" `
        -WorkingDirectory "C:\Users\${env:UserName}\Documents\PowerShell\Modules"
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

# Function to get the last n event logs
function Get-EventLogs {
    Get-WinEvent -LogName application -MaxEvents $args[0]
}

function help {
    Write-Host "Scheduler Module"
    Write-Host "----------------"
    Write-Host "Install-ScheduledTask: Installs a scheduled task to disable Vanguard at 8PM and at logon (With a pop-up of course)."
    Write-Host "Backup-SchedulerTask: Backs up the VanguardController scheduled task as `xml` in Module directory."
    Write-Host "Restore-SchedulerTask: Restores the VanguardController scheduled task."
    Write-Host "Unregister-SchedulerTask: Unregisters the VanguardController scheduled task."
    Write-Host "Get-EventLogs: Get the last n event logs. Usage: Get-EventLogs <number>"
    Write-Host "help: Display this help message."
}
