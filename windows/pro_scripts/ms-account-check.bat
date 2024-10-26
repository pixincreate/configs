@ECHO OFF

if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

echo Changing directory to Office 16
cd c:\Program Files\Microsoft Office\Office16
echo.
echo Getting the Status of Office 
echo.
cscript ospp.vbs /dstatus
echo.
pause.
