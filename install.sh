#!/bin/bash

# Define variables
ROOT_PARTITION="/dev/nvme0n1p1"  # Replace with your root partition
EFI_PARTITION="/dev/nvme0n1p2"  # Replace with your existing EFI partition
NEW_PARTITION="/dev/nvme0n1p3"  # Replace with your new partition
HOSTNAME="my-artix-install"
USERNAME="yourusername"
PASSWORD="yourpassword"
PACKAGES_FILE="packages.txt"

# Format existing partitions
mkfs.vfat -F32 $EFI_PARTITION
mkfs.ext4 $ROOT_PARTITION

# Create and format the new ext4 partition using parted starting at the first available block
parted -s /dev/nvme0n1 mkpart primary ext4 0% 100GiB
mkfs.ext4 $NEW_PARTITION

# Mount partitions
mount $ROOT_PARTITION /mnt
mkdir -p /mnt/boot
mount $EFI_PARTITION /mnt/boot

# Install base system with OpenRC and additional packages from packages.txt
basestrap /mnt base base-devel runit elogind-runit $(cat $PACKAGES_FILE)

# Generate fstab
fstabgen -U /mnt >> /mnt/etc/fstab

# Set hostname
echo "$HOSTNAME" > /mnt/etc/hostname

# Configure network (install and enable NetworkManager)
chroot /mnt pacman -S networkmanager
chroot /mnt ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/

# Set the root password
chroot /mnt passwd

# Create a user and add to wheel group for sudo access
chroot /mnt useradd -m -g users -G wheel -s /bin/bash $USERNAME
chroot /mnt passwd $USERNAME

# Allow members of the wheel group to execute any command with sudo
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

# Install and configure bootloader (GRUB in this example)
chroot /mnt pacman -S grub
chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Enable necessary services
chroot /mnt ln -s /etc/runit/sv/dbus /etc/runit/runsvdir/default/
chroot /mnt ln -s /etc/runit/sv/elogind /etc/runit/runsvdir/default/

# Optional: Install additional software
# chroot /mnt pacman -S your-package

# Unmount partitions
umount -R /mnt

echo "Artix Linux with NetworkManager and additional packages installed successfully!"