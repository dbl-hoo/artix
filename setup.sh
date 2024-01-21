
# install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
echo "done"

# setup arch extra repositories

sudo pacman -S --noconfirm artix-archlinux-support

sudo echo "[extra]
Include = /etc/pacman.d/mirrorlist-arch

[community]
Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf

#update repositories
sudo pacman -Syy