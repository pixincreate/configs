@ECHO OFF

REM Bypass NRO (Network Requirement OOBE) for Windows 11
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /r REG_DWORD /d 1 /f shutdown /r /t 0
