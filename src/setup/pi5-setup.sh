#!/bin/bash

#
# Setup script for Raspberry Pi5 Running Standard Debian Bookworm 64-bit Install
#

# Cleanup Previous Install
echo -e "\n\nCleaning up existing containers, this may take a while!\n\n"
if command -v docker &>/dev/null; then
	containers=$(sudo docker ps -q)

	if [ -n "$containers" ]; then
		sudo docker stop $containers
	fi

	sudo docker system prune --all --force
	sudo docker volume prune --all --force

fi

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install setup deps
sudo apt-get install curl -y

#
#Install Docker
#

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
	sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker $USER

# Deps to build and install kernel module
sudo apt-get install build-essential dkms pciutils -y

# Run lspci -n and filter for vendor 1e60
devices=$(lspci -n | grep -i "1e60")

# Count device IDs
hailo8_count=$(echo "$devices" | grep -ci "1e60:2864")

# Initialize version variable
HAILO_VERSION=""

# Decision logic
if [[ $hailo8_count -gt 0 ]]; then
	HAILO_VERSION="Hailo-8"
	echo "$HAILO_VERSION: $hailo8_count"
else
	echo "No Supported Hailo devices found!"
fi

# Uninstall existing drivers

HAILO_PACKAGES=("hailo10h-driver-fw" "hailort-pcie-driver" "hailo-all")

for pkg in "${HAILO_PACKAGES[@]}"; do
	if dpkg -l | grep -q "^ii  $pkg "; then
		echo "-I- Uninstalling $pkg"
		sudo apt-get remove --purge -y "$pkg"
	else
		echo "-I- $pkg not installed"
	fi
done

# Install appropriate driver
if [[ "$HAILO_VERSION" == "Hailo-8" ]]; then
	curl -fsSLO https://storage.googleapis.com/deepperception_public/hailo/h8/hailort-pcie-driver_4.21.0_all.deb
	yes | sudo dpkg -i hailort-pcie-driver_4.21.0_all.deb
	echo "options hailo_pci force_desc_page_size=4096" | sudo tee -a /etc/modprobe.d/hailo_pci.conf >/dev/null
else
	echo -e "\n\nSupported Hailo configuration not found, skipping driver install and exiting\n\n"
	exit 1
fi

# Set PCI Gen3

CONFIG_FILE="/boot/firmware/config.txt"

add_if_missing() {
	local line="$1"
	if ! grep -Fxq "$line" "$CONFIG_FILE"; then
		echo "$line" | sudo tee -a "$CONFIG_FILE" >/dev/null
		echo "Added: $line"
	else
		echo "Already exists: $line"
	fi
}

add_if_missing "dtparam=pciex1"
add_if_missing "dtparam=pciex1_gen=3"

# Remove downloaded debs
rm *.deb

echo -e "\n\nReboot Needed to Complete Hailo Driver Install!!!\n\n"
