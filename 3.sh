install_packages() {
  # Check if packages.txt exists
  if [ ! -f "packages.txt" ]; then
    echo "Error: packages.txt not found."
    return 1
  fi

  # Read package names from packages.txt and install them
  while IFS= read -r package; do
    sudo pacman -S --noconfirm "$package"
  done < packages.txt

  echo "Installation complete."
}

install_aur_packages() {
  # Check if aur_packages.txt exists
  if [ ! -f "aur_packages.txt" ]; then
    echo "Error: aur_packages.txt not found."
    return 1
  fi

  # Read AUR package names from aur_packages.txt and install them using yay
  while IFS= read -r aur_package; do
    yay -S --noconfirm "$aur_package"
  done < aur_packages.txt

  echo "Installation complete."
}


# install yay
sudo git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# setup arch extra repositories
sudo pacman -S --noconfirm artix-archlinux-support

# enable parallel downloads
sudo sed -i 's/^#\(ParallelDownloads = 5\)/\1/' /etc/pacman.conf
sudo sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf
sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf

# add arch extra repos
sudo sed -i '$a [extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude = /etc/pacman.d/mirrorlist-arch' /etc/pacman.conf

#update repositories
sudo pacman -Syy

#setup terminal with oh-my-zsh, etc.
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k


# install repo packages
install_packages
install_aur_packages

chezmoi init https://github.com/dbl-hoo/dotfiles.git
chezmoi apply