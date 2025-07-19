#!/bin/bash

# Update package lists and upgrade installed packages.
echo "Updating and upgrading Apt packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install specific Apt packages, including build-essential to get a bunch of development tools and libraries.
echo "Installing Apt packages..."
apt_install=("curl" "wget" "git" "vim" "zsh" "build-essential" "autoconf" "make" "libssl-dev" "ca-certificates")
for package in "${apt_install[@]}"; do
  echo "Installing $package..."
  sudo apt-get install -y "$package"
done

# Add the Flatpak repository and install flatpak.
echo "Adding Flatpak repository and installing Flatpak..."
sudo add-apt-repository ppa:flatpak/stable
sudo apt-get update
sudo apt-get install -y flatpak

# Install specific Flatpak packages.
echo "Installing Flatpak packages..."
flatpak_install=("htop" "firefox" "blender" "vlc" "qbittorrent" "filezilla" "curl" "wget")
for package in "${flatpak_install[@]}"; do
  echo "Installing $package..."
  flatpak install --user $package
done

# Install zsh as default shell for the current user.
echo "Setting zsh as default shell..."
sudo chsh -s /bin/zsh

# Add aliases to .zshrc file (or create it if it doesn't exist)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
echo '[ -s "$HOME/.zshrc" ] && source "$HOME/.zshrc"' >> ~/.zshrc
source ~/.zshrc

# Install additional packages not covered by apt or flatpak.
echo "Installing additional packages..."
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-get update
sudo apt-get install -y nvidia-driver

# Install Docker (optional, as it's not mentioned in the list).
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install additional packages you might have missed or that require manual installation.
echo "Manually installing remaining packages..."
sudo apt-get install -y zlib1g-dev inotify-tools qBittorrent uar filezilla brave-browser vs-code docker-compose-plugin terraform flyctl com.obsproject.Studio org.videolan.VLC org.tenacityaudio.Tenacity md.obsidian.Obsidian org.gimp.GIMP rest.insomnia.Insomnia com.github.zadam.trilium com.spotify.Client io.github.shiftey.Desktop Jetbrains Mono Font eddie-ui eza Starship Codium Powerline10k trilium zoxide FZF filezilla qbittorrent
echo "Installation complete."
