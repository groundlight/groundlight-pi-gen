#!/bin/bash 


set -e 

ARCH=arm64
ROOT_DIR=/home/ubuntu
NUM_CORES=${NUM_CORES:-$(nproc)}
IMAGE_FILE=""

# First step: Install the required packages. These include cross-compilers for arm64
# and required packages for QEMU itself. 
# NOTE: We probably don't need to install `qemu-system-gui`
sudo apt install \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        qemu \
        qemubuilder \
        qemu-system-gui \
        qemu-system-arm \
        qemu-utils \
        qemu-system-data \
        qemu-system \
        flex \
        bison \
        libssl-dev 

# Second step: Build the Linux kernel for qemu arm64 
# The kernel can be downloaded from https://www.kernel.org/
# tar xvJf means: -x: extract, -v: verbose, -J: use the xz compression, -f: specify archive name
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.34.tar.xz
tar xvJf linux-6.1.34.tar.xz 
cd linux-6.1.34

# Create a .config file: This requires having flex and bison packages installed: 
# Flex (Fast Lexial Analyzer Generator) is used for tokenizing input (breaking it into a series of tokens)
# and Bison takes these tokens and analyzes their structure to understand the higher-level syntax. 

ARCH=${ARCH} CROSS_COMPILE=/bin/aarch64-linux-gnu- make defconfig

# Use the kvm_guest (kernel virtual machine) config as the base defconfig, which is suitable for qemu 
ARCH=${ARCH} CROSS_COMPILE=/bin/aarch64-linux-gnu- make kvm_guest.config

# Build the kernel (parallelizable if nproc > 1)
ARCH=arm64 CROSS_COMPILE=/bin/aarch64-linux-gnu- make -j${NUM_CORES}

cp arch/${ARCH}/boot/Image ${ROOT_DIR}


# Third step: Mount the image for enabling SSH and configuring username and password 


while getopts "i:" flag; do 
do 
    case "${flag}" in 
        i)
            IMAGE_FILE="${OPTARG}"
            ;;
        *)
            ;;
    esac
done 

function assert_numeric() {
    if ! [[ $1 =~ ^[0-9]+$ ]] || ! [[ $1 =~ ^[0-9]+$ ]]; then
        echo "Error: Non-numeric value detected."
        exit 1
    fi
}

# Check that the image exists 
if [ ! -f "${IMAGE_FILE}" ]; then 
    echo "Invalid Raspberry Pi OS image: '${IMAGE_FILE}'"
    exit 1
fi 


# Extracting sector size
SECTOR_SIZE=$(fdisk -l $IMAGE_FILE | grep "Sector size" | awk '{print $4}')

# Extracting the start of the first partition
START_SECTOR=$(fdisk -l $IMAGE_FILE | grep -E "\.img1" | awk '{print $2}')

assert_numeric $SECTOR_SIZE
assert_numeric $START_SECTOR

# Calculating the offset
OFFSET=$(echo "$SECTOR_SIZE * $START_SECTOR" | bc)


echo "Sector Size: $SECTOR_SIZE"
echo "Start Sector: $START_SECTOR"
echo "Offset: $OFFSET"
        


sudo qemu-img resize \
        /home/ubuntu/groundlight-pi-gen/deploy/image_2023-12-14-GroundlightPi-sdk-qemu.img 4G

# sudo qemu-system-arm \
#     -M raspi2b \ 
#     -m 1G \
#     -drive file=/home/ubuntu/groundlight-pi-gen/deploy/image_2023-12-14-GroundlightPi-sdk-qemu.img,format=raw \
#     -net nic -net user \
#     -display none \
#     -serial stdio

qemu-system-aarch64 \
        -machine virt \
        -cpu cortex-a72 \
        -smp 6 \
        -m 4G \
        -kernel Image \
        -append "root=/dev/vda2 rootfstype=ext4 rw panic=0 console=ttyAMA0" \
        -drive format=raw,file=/home/ubuntu/groundlight-pi-gen/deploy/image_2023-12-14-GroundlightPi-sdk-qemu.img,if=none,id=hd0,cache=writeback \
        -device virtio-blk,drive=hd0,bootindex=0 \
        -netdev user,id=mynet,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=mynet \
        -monitor telnet:127.0.0.1:5555,server,nowait \
        -nographic 



# Remember to add a step to add bison and flex 
# sudo apt-get install flex bison libssl-dev 

# IP address is 10.0.2.15 

# [FAILED] Failed to start rpi-eeprom…k for Raspberry Pi EEPROM updates.
# See 'systemctl status rpi-eeprom-update.service' for details.
# [  OK  ] Started avahi-daemon.service - Avahi mDNS/DNS-SD Stack.