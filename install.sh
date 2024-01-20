#!/bin/bash

# List available drives using lsblk
lsblk
echo "Make sure to identify the correct drive for partitioning."

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

# Prompt for wireless network information
read -p "Enter the SSID (network name): " SSID
read -s -p "Enter the password for $SSID: " PASSWORD
echo

# Configure wireless connection using wpa_supplicant
wpa_passphrase "$SSID" "$PASSWORD" > /mnt/etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# Connect to the wireless network
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
dhcpcd wlan0

# Ping 1.1.1.1 four times
artix-chroot /mnt ping -c 4 1.1.1.1

# Basestrap essential packages and network tools for Artix Linux
basestrap /mnt base base-devel runit elogind-runit os-prober

# Generate fstab
fstabgen -U /mnt >> /mnt/etc/fstab

# Set hostname
echo "my-artix-install" > /mnt/etc/hostname

# Configure network (install and enable NetworkManager)
artix-chroot /mnt pacman -S networkmanager networkmanager-runit
artix-chroot /mnt ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/

# Set the root password
artix-chroot /mnt passwd

# Create a user and add to wheel group for sudo access
artix-chroot /mnt useradd -m -g users -G wheel -s /bin/bash myuser
artix-chroot /mnt passwd myuser

# Allow members of the wheel group to execute any command with sudo
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

# Install and configure bootloader (GRUB in this example)
artix-chroot /mnt pacman -S grub os-prober

# Enable os-prober in grub.cfg
echo "GRUB_DISABLE_OS_PROBER=false" >> /mnt/etc/default/grub

# Detect other operating systems with os-prober
artix-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Identify the EFI partition and install GRUB
EFI_PARTITION="$(lsblk -f $DRIVE | grep 'EFI System Partition' | awk '{print $1}')"
artix-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Artix --recheck --removable

# Enable necessary services
#artix-chroot /mnt ln -s /etc/runit/sv/dbus /etc/runit/runsvdir/default/
#artix-chroot /mnt ln -s /etc/runit/sv/elogind /etc/runit/runsvdir/default/

# Optional: Install additional software
# artix-chroot /mnt pacman -S your-package

# Unmount partitions
umount -R /mnt

echo "Artix Linux with NetworkManager and additional packages installed successfully!"
