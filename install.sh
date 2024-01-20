#!/bin/bash

# Function to print disk information
print_disk_info() {
  lsblk
  echo "Make sure to identify the correct drive for partitioning."
}

# Function to create and mount partitions
create_and_mount_partitions() {
  # Prompt for the drive to partition
  read -p "Enter the drive to partition (e.g., /dev/nvme0n1): " DRIVE

  # List existing partitions on the selected drive
  lsblk $DRIVE
  echo "Make sure to identify the existing partitions on $DRIVE."

  # Create a new 100GB ext4 partition after the existing root partition
  cfdisk $DRIVE

  read -p "Enter the name of the root partition for install (e.g., /dev/nvme0n1p4): " ROOT

  # Format the new partition
  mkfs.ext4 $ROOT

  # Mount the new partition
  mount $ROOT /mnt
}


# Function to perform chroot setup
perform_chroot_setup() {
  #set the clock
  sv up ntpd
  
  # Basestrap essential packages and network tools for Artix Linux
  basestrap /mnt base base-devel runit elogind-runit linux linux-firmware

  # Generate fstab
  fstabgen -U /mnt >> /mnt/etc/fstab

  #  Configure network (adjust accordingly)
  read -p "Enter the desired hostname: " HOSTNAME
  echo "$HOSTNAME" > /mnt/etc/hostname
  echo "127.0.0.1 localhost
  ::1       localhost
  127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /mnt/etc/hosts

  # set the timezone
  artix-chroot /mnt ln -sf /usr/share/zoneinfo/Americas/New_York /etc/localtime

  #Run hwclock to generate /etc/adjtime:
  artix-chroot /mnt hwclock --systohc

  #set the locale
  artix-chroot /mnt echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
  artix-chroot /mnt /etc/locale.gen
  artix-chroot /mnt echo LANG=en_US.UTF-8 >> /etc/locale.conf
  
  # Prompt for username
  read -p "Enter the desired username: " USERNAME

  # Configure network (install and enable NetworkManager)
  artix-chroot /mnt pacman -S networkmanager networkmanger-runit
  artix-chroot /mnt ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/

  # Install and configure bootloader (GRUB in this example)
  artix-chroot /mnt pacman -S grub os-prober 

  # Identify the EFI partition and install GRUB
  EFI_PARTITION="$(lsblk -f $DRIVE | grep 'EFI System Partition' | awk '{print $1}')"
  artix-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Artix --recheck --removable

  # Enable os-prober in grub.cfg
  echo "GRUB_DISABLE_OS_PROBER=false" >> /mnt/etc/default/grub

  # Detect other operating systems with os-prober
  artix-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

  # Allow members of the wheel group to execute any command with sudo
  echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

  # Set the root password
  echo "Enter the new root password: "
  artix-chroot /mnt passwd

  # Create a user and add to wheel group for sudo access
  artix-chroot /mnt useradd -m -g users -G wheel -s /bin/bash $USERNAME
  echo "Enter the new user user password: "
  artix-chroot /mnt passwd $USERNAME

  # Optional: Install additional software
  artix-chroot /mnt pacman -S nano 

  # Unmount partitions
  umount -R /mnt

  echo "Artix Linux with NetworkManager and additional packages installed successfully!"
}

# Main script
print_disk_info
create_and_mount_partitions
perform_chroot_setup
