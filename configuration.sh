#  Configure network (adjust accordingly)
  echo "$HOSTNAME" > /mnt/etc/hostname
  echo "127.0.0.1 localhost
  ::1       localhost
  127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /mnt/etc/hosts

  
  # set the timezone
  ln -sf /usr/share/zoneinfo/Americas/New_York /etc/localtime

  #Run hwclock to generate /etc/adjtime:
  hwclock --systohc

  #set the locale
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" >> /etc/locale.conf
  
  # Install network manager, grub, os-prober and enable networkmanager
  pacman -S --noconfirm networkmanager networkmanager-runit grub os-prober git neofetch
  ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Artix --recheck --removable

  # Enable os-prober in grub.cfg
  echo "GRUB_DISABLE_OS_PROBER=false" >> /mnt/etc/default/grub

  # Detect other operating systems with os-prober
  grub-mkconfig -o /boot/grub/grub.cfg

  # Allow members of the wheel group to execute any command with sudo
  echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

  # Create a user and add to wheel group for sudo access
  useradd -m -G wheel,sys,rfkill,video,audio,input,power,storage,optical,lp,scanner,dbus,uucp $USERNAME

  #change passwords
  passwd
  passwd $USERNAME

  #create directory and copy scripts
  mkdir /home/$USERNAME/install
  cp setup.sh /home/$USERNAME/install
  cp packages.txt /home/$USERNAME/install
  cp aur_packages.txt /home/$USERNAME/install
