
# install yay
#git clone https://aur.archlinux.org/yay.git
#cd yay
#makepkg -si
#echo "done"

# setup arch extra repositories

#sudo pacman -S --noconfirm artix-archlinux-support

sed -i 's/^#\(ParallelDownloads = 5\)/\1/' /etc/pacman.conf

#update repositories
sudo pacman -Syy