log_file="install_log.txt"

install_packages() {
  while IFS= read -r package; do
    sudo pacman -S --noconfirm "$package" 2>> "$log_file"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to install package $package. Check $log_file for details." >&2
      return 1
    fi
  done < ~/install/packages.txt

  echo "Installation of packages complete."
}

install_aur_packages() {
  while IFS= read -r aur_package; do
    yay -S --noconfirm "$aur_package" 2>> "$log_file"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to install AUR package $aur_package. Check $log_file for details." >&2
      return 1
    fi
  done < ~/install/aur_packages.txt

  echo "Installation of AUR packages complete."
}

install_yay() {
  echo "Installing yay..."
  git clone https://aur.archlinux.org/yay.git 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to clone yay repository. Check $log_file for details." >&2
    return 1
  fi

  cd yay 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to change directory to yay. Check $log_file for details." >&2
    return 1
  fi

  makepkg -si 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to build and install yay. Check $log_file for details." >&2
    return 1
  fi

  cd 2>> "$log_file"
  echo "yay installed successfully."
}

configure_pacman () {
  sudo pacman -S --noconfirm artix-archlinux-support 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install artix-archlinux-support. Check $log_file for details." >&2
    return 1
  fi

  # enable parallel downloads
  sudo sed -i 's/^#\(ParallelDownloads = 5\)/\1/' /etc/pacman.conf 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to enable parallel downloads in pacman.conf. Check $log_file for details." >&2
    return 1
  fi

  sudo sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to enable color in pacman.conf. Check $log_file for details." >&2
    return 1
  fi

  sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to add ILoveCandy to pacman.conf. Check $log_file for details." >&2
    return 1
  fi

  # add arch extra repos
  sudo sed -i '$a [extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude = /etc/pacman.d/mirrorlist-arch' /etc/pacman.conf 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to add Arch extra repos to pacman.conf. Check $log_file for details." >&2
    return 1
  fi

  # update repositories
  sudo pacman -Syy 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to update repositories. Check $log_file for details." >&2
    return 1
  fi

  echo "Pacman configured successfully."
}

configure_zsh() {
  # setup terminal with oh-my-zsh, etc.
  echo "Setting up zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install oh-my-zsh. Check $log_file for details." >&2
    return 1
  fi

  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k 2>> "$log_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to clone powerlevel10k repository. Check $log_file for details." >&2
    return 1
  fi

  echo "Zsh configured successfully."
}

# install repo packages
install_yay
configure_pacman
install_packages
install_aur_packages
configure_zsh
chezmoi init --apply dbl-hoo
