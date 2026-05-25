#!/bin/bash
set -euo pipefail # Exit immediately if a command exits with a non-zero status

# 1. OS DETECTION & VARIABLES
if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script as root/sudo directly. Run it as a normal user."
    echo "The script will prompt for sudo access when needed."
    exit 1
fi

CURRENT_USER=$(whoami)
USER_HOME=$HOME

# Authenticate sudo upfront
echo "Authenticating sudo access..."
sudo -v

# Keep-alive sudo until script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    DISTRO_LIKE=$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')
else
    echo "Cannot determine OS distribution. /etc/os-release missing."
    exit 1
fi

# Detect family
IS_DEBIAN_LIKE=false
IS_ARCH_LIKE=false

if [[ "$DISTRO_ID" =~ (ubuntu|debian|pop|mint) || "$DISTRO_LIKE" =~ (ubuntu|debian) ]]; then
    IS_DEBIAN_LIKE=true
elif [[ "$DISTRO_ID" =~ (arch|manjaro|endeavouros) || "$DISTRO_LIKE" =~ (arch) ]]; then
    IS_ARCH_LIKE=true
fi

if [ "$IS_DEBIAN_LIKE" = false ] && [ "$IS_ARCH_LIKE" = false ]; then
    echo "Unsupported OS distribution: $ID"
    exit 1
fi

echo "Starting deployment script for user: $CURRENT_USER on $ID"

# 2. SHARED TASKS (Runs on both systems)
echo "-----------------------------------------------"
echo "Resetting SSH directory permissions..."
echo "-----------------------------------------------"
if [ -d "$USER_HOME/.ssh" ]; then
    chmod 700 "$USER_HOME/.ssh"
    find "$USER_HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} +
    find "$USER_HOME/.ssh" -type f ! -name "*.pub" -exec chmod 600 {} +
fi

# 3. DISTRO SPECIFIC APPLICATIONS
if [ "$IS_DEBIAN_LIKE" = true ]; then
    echo "-----------------------------------------------"
    echo "Running Debian-based Setup Tasks"
    echo "-----------------------------------------------"

    # Prerequisite updates
    sudo apt update
    sudo apt install -y curl wget git gpg software-properties-common ca-certificates

    # AirVPN Eddie repository
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://eddie.website/repository/keys/eddie_maintainer_gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/eddie-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/eddie-keyring.gpg] http://eddie.website/repository/apt stable main" | sudo tee /etc/apt/sources.list.d/eddie.website.list > /dev/null

    # Eza repository
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

    # Fastfetch PPA (Only on Ubuntu/PPAs supported distros)
    if [ "$DISTRO_ID" = "ubuntu" ] || [[ "$DISTRO_LIKE" =~ "ubuntu" ]]; then
        sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
    fi

    # Refresh and Bulk Install Native APT Apps
    sudo apt update

    # Build package list dynamically
    DEB_APPS=(
        eza bat zsh build-essential autoconf make
        libssl-dev htop blender vlc filezilla inotify-tools fzf
        docker-compose docker.io ansible zsh-autosuggestions
        zsh-syntax-highlighting flatpak zoxide eddie-ui
    )

    # Check if fastfetch is available in repositories, otherwise flag for manual install
    INSTALL_FASTFETCH_VIA_GITHUB=false
    if apt-cache show fastfetch >/dev/null 2>&1; then
        DEB_APPS+=(fastfetch)
    else
        INSTALL_FASTFETCH_VIA_GITHUB=true
    fi

    sudo apt install -y "${DEB_APPS[@]}"

    if [ "$INSTALL_FASTFETCH_VIA_GITHUB" = true ]; then
        echo "Installing Fastfetch via GitHub Release..."
        FASTFETCH_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "browser_download_url" | grep "linux-amd64.deb" | cut -d '"' -f 4 || echo "")
        if [ -n "$FASTFETCH_URL" ]; then
            wget -O /tmp/fastfetch.deb "$FASTFETCH_URL"
            sudo apt install -y /tmp/fastfetch.deb
            rm /tmp/fastfetch.deb
        else
            echo "Warning: Could not fetch fastfetch download link from GitHub. Skipping fastfetch..."
        fi
    fi

    # Docker Post-Install Configuration
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$CURRENT_USER"

    # Install Alacritty via APT if available, otherwise Snap fallback
    if apt-cache show alacritty >/dev/null 2>&1; then
        sudo apt install -y alacritty
    else
        echo "Alacritty not found in apt repos, installing via snap..."
        sudo apt install -y snapd
        sudo snap install alacritty --classic
    fi

    # Cleanup
    sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y

elif [ "$IS_ARCH_LIKE" = true ]; then
    echo "-----------------------------------------------"
    echo "Running Arch-based Setup Tasks"
    echo "-----------------------------------------------"

    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm --needed git curl wget base-devel

    # Native Arch Equivalents
    sudo pacman -S --noconfirm --needed \
        bat zsh openssl ca-certificates htop blender vlc filezilla \
        inotify-tools eza fzf docker docker-compose ansible \
        zsh-autosuggestions zsh-syntax-highlighting flatpak fastfetch \
        alacritty zoxide starship

    # Docker Post-Install Configuration
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$CURRENT_USER"

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

# 4. UNIVERSAL CONFIGURATIONS & THEMES
echo "-----------------------------------------------"
echo "Setting up universal configuration and themes..."
echo "-----------------------------------------------"

# Install Starship on Debian/Ubuntu (already installed on Arch)
if [ "$IS_DEBIAN_LIKE" = true ]; then
    if ! command -v starship >/dev/null 2>&1; then
        echo "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    fi
fi

# Ensure configuration files exist
touch "$USER_HOME/.zshrc"
touch "$USER_HOME/.bashrc"

# Configure shell scripts for Zoxide
for rc in ".zshrc" ".bashrc"; do
    shell_name=$(echo "$rc" | sed 's/\.//;s/rc//')
    if ! grep -q "zoxide init $shell_name" "$USER_HOME/$rc"; then
        echo "eval \"\$(zoxide init $shell_name)\"" >> "$USER_HOME/$rc"
    fi
done

# Initialize Starship in bashrc
if ! grep -q "starship init bash" "$USER_HOME/.bashrc"; then
    echo 'eval "$(starship init bash)"' >> "$USER_HOME/.bashrc"
fi

# Configure Zsh plugins
SUGGEST_PATHS=(
    "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
)
for path in "${SUGGEST_PATHS[@]}"; do
    if [ -f "$path" ]; then
        if ! grep -q "$path" "$USER_HOME/.zshrc"; then
            echo "source $path" >> "$USER_HOME/.zshrc"
        fi
        break
    fi
done

HIGHLIGHT_PATHS=(
    "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
)
for path in "${HIGHLIGHT_PATHS[@]}"; do
    if [ -f "$path" ]; then
        if ! grep -q "$path" "$USER_HOME/.zshrc"; then
            echo "source $path" >> "$USER_HOME/.zshrc"
        fi
        break
    fi
done

# Powerlevel10k Setup
echo "-----------------------------------------------"
echo "Installing Powerlevel10k..."
echo "-----------------------------------------------"
if [ ! -d "$USER_HOME/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/powerlevel10k"
fi

if ! grep -q "powerlevel10k.zsh-theme" "$USER_HOME/.zshrc"; then
    echo "source ~/powerlevel10k/powerlevel10k.zsh-theme" >> "$USER_HOME/.zshrc"
fi

# 5. FLATPAK APPLICATIONS
echo "-----------------------------------------------"
echo "Installing Flatpak Applications..."
echo "-----------------------------------------------"
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Appending '|| true' ensures the script finishes even if Flatpak encounters minor warnings
sudo flatpak install -y flathub \
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
