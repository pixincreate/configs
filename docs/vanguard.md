# Vanguard-Controller

[vanguard.ps1](https://github.com/pixincreate/configs/blob/main/windows/powershell/modules/vanguard.ps1) is a special file called by powershell profile targeted at users who play Valorant.
It is a controller file that allows you to either `enable` or `disable` `vgc` and `vgk` along with an option to check their status (`vgk_status`).
This is added as a measure to stop Vanguard from spying on its users all the time. Enable the rootkit, reboot and then start playing.

> [!NOTE]
> After enabling, you need to restart your system to for Vanguard to initiate the surveillance.

Usage:

- Enable Vanguard

  ```shell
  vanguard enable
  ```

- Disable Vanguard

  ```shell
  vanguard disable
  ```

- Check Status

  ```shell
  vanguard vgk_status
  ```

## Vanguard-Controller-Scheduler

[vanguard-scheduler.ps1](https://github.com/pixincreate/configs/blob/main/windows/powershell/modules/vanguard_scheduler.ps1) is another powershell script that can called by powershell profile to control the scheduler for ease of use.

Usage:

- help

  ```shell
  vanguard_scheduler help
  ```

- Install-ScheduledTask

  ```shell
  vanguard_scheduler Install-ScheduledTask
  ```

- Backup-SchedulerTask

  ```shell
  vanguard_scheduler Backup-SchedulerTask
  ```

- Restore-SchedulerTask

  ```shell
  vanguard_scheduler Restore-SchedulerTask
  ```

- Unregister-SchedulerTask

  ```shell
  vanguard_scheduler Unregister-SchedulerTask
  ```

- Get-EventLog

  ```shell
  vanguard_scheduler Get-EventLog
  # mandatory input -> number: <number>
  ```

### Some references

[I Don't Trust Riot Games...](https://youtu.be/H1b46boE1Rk)
[Is Valorant Spyware](https://youtu.be/UqLI1xKc-L4)
[why riot's new anti-cheat is a HUGE problem](https://youtu.be/nk6aKV2rY7E?feature=shared)
[The controversy over Riot's Vanguard anti-cheat software, explained](https://www.pcgamer.com/the-controversy-over-riots-vanguard-anti-cheat-software-explained/)
[Valorant developers speak out on Vanguard security concerns - MSN](https://www.msn.com/en-us/news/technology/valorant-developers-speak-out-on-vanguard-security-concerns/ar-AA1o6ptR)
