vi#!/bin/bash

# Function to print disk information
print_disk_info() {
  lsblk
  echo "Make sure to identify the correct drive for partitioning."
}

# Function to create and mount partitions

set_variables() {
  read -p "Enter hostname: " HOSTNAME
  read -p "Enter username: " USERNAME
}

create_and_mount_partitions() {
  # Prompt for the drive to partition
  read -p "Enter the drive to partition (e.g., /dev/nvme0n1): " DRIVE

  # List existing partitions on the selected drive
  lsblk $DRIVE
  echo "Make sure to identify the existing partitions on $DRIVE."

  # Create a new 100GB ext4 partition after the existing root partition
  cfdisk $DRIVE

  lsblk -f $DRIVE
  read -p "Enter the name of the efi partition: " EFI
  read -p "Enter the name of the root partition for install (e.g., /dev/nvme0n1p4): " ROOT
  
  # Format the new partition
  mkfs.ext4 $ROOT

  # Mount the new partition
  mount $ROOT /mnt
}

# Function to check and format EFI partition
format_efi_partition() {

  # Prompt to format the EFI partition
  read -p "Found EFI partition: $EFI Do you want to format it as FAT32? (y/n): " FORMAT_CONFIRM

  # Check user input
  if [ "$FORMAT_CONFIRM" == "y" ] || [ "$FORMAT_CONFIRM" == "Y" ]; then
    # Format EFI partition as FAT32
    echo "Formatting $EFI as FAT32..."
    mkfs.fat -F32 $EFI
    echo "EFI partition formatted successfully."
  elif [ "$FORMAT_CONFIRM" == "n" ] || [ "$FORMAT_CONFIRM" == "N" ]; then
    echo "EFI partition will not be formatted. Exiting."
  else
    echo "Invalid input. Exiting."
    exit 1
  fi

  mkdir -p /mnt/boot/efi
  mount $EFI /mnt/boot/efi
}

# Function to perform basic setup
basic_setup() {
  #set the clock
  sv up ntpd
  
  # Basestrap essential packages and network tools for Artix Linux
  basestrap /mnt base base-devel runit elogind-runit linux linux-firmware intel-ucode nano

  # Generate fstab
  fstabgen -U /mnt >> /mnt/etc/fstab

  #copy files to /mnt
  mkdir /mnt/artixinstall
  cp configuration.sh /mnt/artixinstall
  cp packages.txt /mnt/artixinstall
  cp aur_packages.next /mnt/artixinstall

  #launch the confinguration script
  artix-chroot /mnt ./artixinstall/configuration.sh
}

# Main script
set_variables
print_disk_info
create_and_mount_partitions
format_efi_partition
basic_setup
