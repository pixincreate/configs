
wsl --install -d Debian

@REM Delete the installer file put before the PC restarted
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\wsl_install.cmd"

echo "Set up your WSL\nExecute dotfiles.sh to set up Debian: sh dotfiles.sh"
