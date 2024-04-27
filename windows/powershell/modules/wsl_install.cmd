
wsl --install -d Debian
wsl --set-default Debian

@REM Delete the installer file put before the PC restarted
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\wsl_install.cmd"
@REM Delete the installer folder
rmdir /s "%USERNAME%\Desktop\configs"

echo "Set up your WSL by executing dotfiles.sh to set up Debian:"
echo "sudo apt-get update && sudo apt-get install -y curl git wget zsh && curl -sSL https://github.com/pixincreate/configs/raw/main/unix/dotfiles.sh | bash"
