#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status

# 1. OS DETECTION & VARIABLES
CURRENT_USER=$(whoami)
USER_HOME="/home/$CURRENT_USER"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_NAME=$ID
else
    echo "Cannot determine OS distribution. /etc/os-release missing."
    exit 1
fi

echo "Starting deployment script for user: $CURRENT_USER on $DISTRO_NAME"

# 2. SHARED TASKS (Runs on both systems)
echo "-----------------------------------------------"
echo "Resetting SSH directory permissions..."
echo "-----------------------------------------------"
if [ -d "$USER_HOME/.ssh" ]; then
    chmod 700 "$USER_HOME/.ssh"
    if ls "$USER_HOME/.ssh"/*.pub > /dev/null 2>&1; then
        chmod 644 "$USER_HOME/.ssh"/*.pub
    fi
    if [ -f "$USER_HOME/.ssh/id_rsa" ]; then
        chmod 600 "$USER_HOME/.ssh/id_rsa"
    fi
fi

# 3. DISTRO SPECIFIC APPLICATIONS
if [ "$DISTRO_NAME" = "ubuntu" ] || [ "$DISTRO_NAME" = "debian" ]; then
    echo "-----------------------------------------------"
    echo "Running Ubuntu/Debian Setup Tasks"
    echo "-----------------------------------------------"
    
    # Prerequisite updates
    sudo apt update && sudo apt install -y curl wget git gpg software-properties-common ca-certificates

    # AirVPN Eddie repository
    curl -fsSL https://eddie.website/repository/keys/eddie_maintainer_gpg.key | sudo tee /usr/share/keyrings/eddie.website-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/eddie.website-keyring.asc] http://eddie.website/repository/apt stable main" | sudo tee /etc/apt/sources.list.d/eddie.website.list
    
    # Eza repository
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    
    # Fastfetch PPA
    sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
    
    # install Primary APT Apps
    sudp apt install -y curl wget git gpg software-properties-common ca-certificates
    
    # Refresh and Bulk Install Native APT Apps
    sudo apt update
    sudo apt install -y \
        eza bat zsh build-essential autoconf make \
        libssl-dev htop blender vlc filezilla inotify-tools fzf \
        docker-compose ansible zsh-autosuggestions zsh-syntax-highlighting flatpak

    # Snap fallback for Alacritty
    sudo apt install -y snapd
    sudo snap install alacritty --classic

    # Cleanup
    sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y

elif [ "$DISTRO_NAME" = "arch" ]; then
    echo "-----------------------------------------------"
    echo "Running Arch Linux Setup Tasks"
    echo "-----------------------------------------------"
    
    sudo pacman -Syu --noconfirm
    
    # install Primary APT Apps
    sudp pacman -S git curl wget --noconfirm --needed

    # Native Arch Equivalents 
    sudo pacman -S --noconfirm --needed \
        curl wget git bat zsh base-devel openssl ca-certificates \
        htop blender vlc filezilla inotify-tools eza fzf docker-compose \
        ansible zsh-autosuggestions zsh-syntax-highlighting flatpak fastfetch alacritty

    # Automated Yay Installation
    if ! command -v yay >/dev/null 2>&1; then
        echo "-----------------------------------------------"
        echo "Installing YAY (AUR Helper)..."
        echo "-----------------------------------------------"
        
        YAY_BUILD_DIR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$YAY_BUILD_DIR"
        
        # Build and install as user
        (cd "$YAY_BUILD_DIR" && makepkg -si --noconfirm)
        rm -rf "$YAY_BUILD_DIR"
    else
        echo "yay is already installed. Skipping..."
    fi

    # Use Yay for AirVPN Eddie
    echo "-----------------------------------------------"
    echo "Installing AirVPN Eddie via AUR..."
    echo "-----------------------------------------------"
    yay -S --noconfirm eddie-ui
fi

# 4. UNIVERSAL INDEPENDENT BINARIES
echo "-----------------------------------------------"
echo "Installing Zoxide..."
echo "-----------------------------------------------"
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Configure shell scripts safely
for rc in ".zshrc" ".bashrc"; do
    if [ -f "$USER_HOME/$rc" ]; then
        shell_name=$(echo "$rc" | sed 's/\.//;s/rc//')
        if ! grep -q "zoxide init $shell_name" "$USER_HOME/$rc"; then
            echo "eval \"\$(zoxide init $shell_name)\"" >> "$USER_HOME/$rc"
        fi
    fi
done

echo "-----------------------------------------------"
echo "Installing Starship..."
echo "-----------------------------------------------"
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "-----------------------------------------------"
echo "Installing Powerlevel10k..."
echo "-----------------------------------------------"
if [ ! -d "$USER_HOME/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/powerlevel10k"
fi

if [ -f "$USER_HOME/.zshrc" ]; then
    if ! grep -q "powerlevel10k.zsh-theme" "$USER_HOME/.zshrc"; then
        echo "source ~/powerlevel10k/powerlevel10k.zsh-theme" >> "$USER_HOME/.zshrc"
    fi
fi

# 5. FLATPAK APPLICATIONS
echo "-----------------------------------------------"
echo "Installing Flatpak Applications..."
echo "-----------------------------------------------"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Appending '|| true' ensures the script finishes even if Flatpak encounters minor warnings
flatpak install -y flathub \
    com.obsproject.Studio \
    org.tenacityaudio.Tenacity \
    md.obsidian.Obsidian \
    org.gimp.GIMP \
    com.github.zadam.trilium \
    com.spotify.Client \
    io.github.shiftey.Desktop \
    com.brave.Browser \
    com.visualstudio.code \
    org.qbittorrent.qBittorrent \
    org.wezfurlong.wezterm || true

echo "-----------------------------------------------"
echo "Deployment Complete! Please restart your terminal."
echo "-----------------------------------------------"