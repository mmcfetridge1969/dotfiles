-
#!/bin/sh
# Define and Add 1920x1080 screen Resolution
# cvt 1920 1080
xrandr --newmode "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
xrandr --newmode "1600x900_60.00"  118.25  1600 1696 1856 2112  900 903 908 934 -hsync +vsync
xrandr --addmode eDP-1 1920x1080_60.00
xrandr --addmode eDP-1 1600x900_60.00
#xrandr --output eDP-1 --mode 1600x900_60.00
xrandr --output eDP-1 --mode 1920x1080_60.00

# Install Airvpn Client (eddie)
curl -fsSL https://eddie.website/repository/keys/eddie_maintainer_gpg.key | sudo tee /usr/share/keyrings/eddie.website-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/eddie.website-keyring.asc] http://eddie.website/repository/apt stable main" | sudo tee /etc/apt/sources.list.d/eddie.website.list
sudo apt update
sudo apt install eddie-ui -y

# Install EZA
sudo apt update
sudo apt install -y gpg
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# Install Starship
curl -sS https://starship.rs/install.sh | sh
eval "$(starship init bash)"
eval "$(starship init zsh)"

# Resetting Permissions on SSH directory
chmod 700 /home/miker/.ssh
chmod 644 /home/miker/.ssh/*.pub
chmod 600 /home/miker/.ssh/id_rsa

# VS Codium Install
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list

sudo apt update && sudo apt install codium -y

# Install the latest stable versions of Docker CLI, Docker Engine, and their dependencies
# Download the Docker script
curl -fsSL https://get.docker.com -o install-docker.sh
# Run the script either as root, or using sudo to perform the installation.
sudo sh install-docker.sh
sudo usermod -aG docker $USER

# Install Powerline10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

# Install trilium notes
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install flathub com.github.zadam.trilium -y

# Install zoxide (cd replacer)
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
eval "$(zoxide init zsh)"
eval "$(zoxide init bash)"

# Installl FZF
sudo apt install fzf -y
# git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
# ~/.fzf/install

# Install Brave Browser
curl -fsS https://dl.brave.com/install.sh | sh

# Install FileZilla
sudo apt install filezilla -y

# Install Qbittorrent
sudo apt install qbittorrent -y

# APT Clean up
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y
