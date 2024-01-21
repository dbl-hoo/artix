
# install yay
#git clone https://aur.archlinux.org/yay.git
#cd yay
#makepkg -si
#echo "done"

# setup arch extra repositories

#sudo pacman -S --noconfirm artix-archlinux-support

sudo sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf

#update repositories
sudo pacman -Syy