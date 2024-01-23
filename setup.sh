install_packages() {

  while IFS= read -r package; do
    sudo pacman -S --noconfirm "$package"
  done < ~/install/packages.txt

  echo "Installation complete."
}

install_aur_packages() {
  while IFS= read -r aur_package; do
    yay -S --noconfirm "$aur_package"
  done < ~/install/aur_packages.txt

  echo "Installation complete."
}

install_yay() {
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd
}

configure_pacman () {
  sudo pacman -S --noconfirm artix-archlinux-support

  # enable parallel downloads
  sudo sed -i 's/^#\(ParallelDownloads = 5\)/\1/' /etc/pacman.conf
  sudo sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf
  sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf

  # add arch extra repos
  sudo sed -i '$a [extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude = /etc/pacman.d/mirrorlist-arch' /etc/pacman.conf

  #update repositories
  sudo pacman -Syy
}

configure_zsh() {
    #setup terminal with oh-my-zsh, etc.
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
}

# install repo packages
install_yay
configure_pacman
install_packages
install_aur_packages
configure_zsh
chezmoi init --apply dbl-hoo