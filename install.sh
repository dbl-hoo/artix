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
  NEW_PARTITION="$(parted -s $DRIVE mkpart primary ext4 0% 100GB | grep -oE '/dev/[^ ]+')"

  # Format the new partition
  mkfs.ext4 $NEW_PARTITION

  # Mount the new partition
  mount $NEW_PARTITION /mnt
}

# Function to configure wireless network
configure_wireless_network() {
  # Prompt for wireless network information
  read -p "Enter the SSID (network name): " SSID
  read -s -p "Enter the password for $SSID: " PASSWORD
  echo

  # Configure wireless connection using wpa_supplicant
  wpa_passphrase "$SSID" "$PASSWORD" > /mnt/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
}

# Function to perform chroot setup
perform_chroot_setup() {
  # Basestrap essential packages and network tools for Artix Linux
  basestrap /mnt base base-devel runit elogind-runit os-prober

  # Generate fstab
  fstabgen -U /mnt >> /mnt/etc/fstab

  # Prompt for hostname
  read -p "Enter the desired hostname: " HOSTNAME
  echo "$HOSTNAME" > /mnt/etc/hostname

  # Prompt for username
  read -p "Enter the desired username: " USERNAME

  # Configure network (install and enable NetworkManager)
  artix-chroot /mnt pacman -S networkmanager wpa_supplicant
  artix-chroot /mnt ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/

  # Set up wpa_supplicant in chroot
  cp /etc/wpa_supplicant/wpa_supplicant-wlan0.conf /mnt/etc/wpa_supplicant/wpa_supplicant-wlan0.conf

  # Connect to the wireless network
  artix-chroot /mnt wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
  artix-chroot /mnt dhcpcd wlan0

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
  artix-chroot /mnt passwd

  # Create a user and add to wheel group for sudo access
  artix-chroot /mnt useradd -m -g users -G wheel -s /bin/bash $USERNAME
  artix-chroot /mnt passwd $USERNAME

  # Optional: Install additional software
  # artix-chroot /mnt pacman -S your-package

  # Unmount partitions
  umount -R /mnt

  echo "Artix Linux with NetworkManager and additional packages installed successfully!"
}

# Main script
print_disk_info
create_and_mount_partitions
configure_wireless_network
perform_chroot_setup
