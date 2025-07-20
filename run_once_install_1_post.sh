#!/bin/sh

# Software Installation Script
# Installs: AirVPN Eddie, EZA, Starship, VSCodium, Docker, Powerlevel10k, Trilium, Zoxide, FZF

set -e  # Exit on any error

# Get current user
CURRENT_USER=$(whoami)
USER_HOME="/home/$CURRENT_USER"

echo "Starting software installation for user: $CURRENT_USER"


echo "###############################################"
echo "###############################################"
echo "Installing AirVPN Eddie..."
echo "###############################################"
echo "###############################################"
curl -fsSL https://eddie.website/repository/keys/eddie_maintainer_gpg.key | sudo tee /usr/share/keyrings/eddie.website-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/eddie.website-keyring.asc] http://eddie.website/repository/apt stable main" | sudo tee /etc/apt/sources.list.d/eddie.website.list
sudo apt update
sudo apt install eddie-ui -y


echo "###############################################"
echo "###############################################"
echo "Installing EZA..."
echo "###############################################"
echo "###############################################"
sudo apt update
sudo apt install -y gpg
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza


echo "###############################################"
echo "###############################################"
echo "Reset SSH directory permissions (if SSH directory exists)"
echo "###############################################"
echo "###############################################"
if [ -d "$USER_HOME/.ssh" ]; then
    echo "Setting SSH permissions..."
    chmod 700 "$USER_HOME/.ssh"
    if ls "$USER_HOME/.ssh"/*.pub 1> /dev/null 2>&1; then
        chmod 644 "$USER_HOME/.ssh"/*.pub
    fi
    if [ -f "$USER_HOME/.ssh/id_rsa" ]; then
        chmod 600 "$USER_HOME/.ssh/id_rsa"
    fi
fi

echo "###############################################"
echo "###############################################"
echo "Installing Zoxide..."
echo "###############################################"
echo "###############################################"
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

 Add zoxide init to shell configs if they exist
if [ -f "$USER_HOME/.zshrc" ]; then
    if ! grep -q "zoxide init zsh" "$USER_HOME/.zshrc"; then
        echo 'eval "$(zoxide init zsh)"' >> "$USER_HOME/.zshrc"
    fi
fi

if [ -f "$USER_HOME/.bashrc" ]; then
    if ! grep -q "zoxide init bash" "$USER_HOME/.bashrc"; then
        echo 'eval "$(zoxide init bash)"' >> "$USER_HOME/.bashrc"
    fi
fi


echo "###############################################"
echo "###############################################"
echo "Installing fastfetch"
echo "###############################################"
echo "###############################################"
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install fastfetch


echo "###############################################"
echo "###############################################"
echo "Installing Alacritty"
echo "###############################################"
echo "###############################################"
sudo apt install snapd
sudo snap install alacritty --classic


echo "###############################################"
echo "###############################################"
echo "Performing system cleanup..."
echo "###############################################"
echo "###############################################"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y


echo "###############################################"
echo "###############################################"
echo "Installing Starship..."
echo "###############################################"
echo "###############################################"
curl -sS https://starship.rs/install.sh | sh


echo "###############################################"
echo "###############################################"
echo "Installing Powerlevel10k..."
echo "###############################################"
echo "###############################################"
Sudo apt install git wget curl -y
if [ ! -d "$USER_HOME/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/powerlevel10k"
fi
# Only add to .zshrc if it exists and line isn't already there
if [ -f "$USER_HOME/.zshrc" ]; then
    if ! grep -q "powerlevel10k.zsh-theme" "$USER_HOME/.zshrc"; then
        echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$USER_HOME/.zshrc"
    fi
else
    echo "Warning: .zshrc not found. Powerlevel10k source line not added."
fi


echo "###############################################"
echo "###############################################"
echo "Installation complete!"
echo "###############################################"
echo "###############################################"
echo "Note: You may need to log out and back in for Docker group membership to take effect."
echo "Note: Restart your shell or source your shell config files to use new tools."
echo ""
echo "Please install the following apps manually"
echo "Install Terraform autocomplete for Zsh"
echo "Add flyctl completion to .zshrc"

