
# install yay
#git clone https://aur.archlinux.org/yay.git
#cd yay
#makepkg -si
#echo "done"

# setup arch extra repositories

#sudo pacman -S --noconfirm artix-archlinux-support

# enable parallel downloads
sudo sed -i 's/^#\(ParallelDownloads = 5\)/\1/' /etc/pacman.conf
sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf
sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf

# add arch extra repos
sed -i '/^\[core\]/a [extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude = /etc/pacman.d/mirrorlist-arch' /etc/pacman.conf


#update repositories

sudo pacman -Syy