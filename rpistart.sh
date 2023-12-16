#!/bin/bash 


set -e 


cd "$(dirname "$0")"


ARCH=arm64
ROOT_DIR=/home/ubuntu
NUM_CORES=${NUM_CORES:-$(nproc)}
IMAGE_FILE=""
KERNEL_VERSION="linux-6.1.34"


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
if [ -d "$KERNEL_VERSION" ]; then
    echo "Directory $KERNEL_VERSION already exists, skipping download and extraction."
else
    # Downloading the kernel source
    echo "Downloading Linux kernel version $KERNEL_VERSION..."
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_VERSION}.tar.xz"

    # Extracting the kernel source
    echo "Extracting ${KERNEL_VERSION}.tar.xz..."
    tar xvJf "${KERNEL_VERSION}.tar.xz"
fi

cd "$KERNEL_VERSION"

# Create a .config file: This requires having flex and bison packages installed: 
# Flex (Fast Lexial Analyzer Generator) is used for tokenizing input (breaking it into a series of tokens)
# and Bison takes these tokens and analyzes their structure to understand the higher-level syntax. 

ARCH=${ARCH} CROSS_COMPILE=/bin/aarch64-linux-gnu- make defconfig

# Use the kvm_guest (kernel virtual machine) config as the base defconfig, which is suitable for qemu 
ARCH=${ARCH} CROSS_COMPILE=/bin/aarch64-linux-gnu- make kvm_guest.config

# Build the kernel (parallelizable if nproc > 1)
ARCH=arm64 CROSS_COMPILE=/bin/aarch64-linux-gnu- make -j${NUM_CORES}

cp arch/${ARCH}/boot/Image ${ROOT_DIR}


# Third step: Mount the image for enabling SSH and configuring username and password and 
# accessing the files within the image. 
# Disk images, like those used for Raspberry Pi (e.g., RaspiOS), often contain an entire 
# disk's worth of data, including the partition table and multiple partitions. 
# To mount a specific partition within this image, we must calculate the correct offset where 
# the partition starts. This calculation requires two pieces of information:
# * sector size 
# * starting offset 
# For instance, if a partition starts at sector 8192 and the sector size is 512 bytes, the byte
# offset of the partition is 8192 * 512 bytes from the start of the image.
#
# We have two partitions inside the generated Raspberry Pi image. The first device (partition)
# is the bootable partition, and the second one is the root filesystem. The first partition is 
# what will be mounted as /boot in Raspberry Pi, and this is where we'll need to create some files.


while getopts "i:" flag
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

# Check that the image exists. The image path is expected to be absolute. 
if [ ! -f "$IMAGE_FILE" ]; then 
    echo "Invalid Raspberry Pi OS image: '$IMAGE_FILE'"
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


# Mount the image in /mnt/rpi directory 
sudo mkdir -p /mnt/rpi 
sudo mount -o loop,offset=${OFFSET} ${IMAGE_FILE} /mnt/rpi

# Create a file named ssh to enable `ssh``. Then, create a file named `userconf.txt` in the same 
# directory and put the username and password there like <username>:<password>. This will be 
# used as the default login credentials. We can configure the password and username to be more 
# robust, but for now we will just use <pi>:<groundlight>. 
cd /mnt/rpi 
sudo touch ssh 

# Generate a hashed password
echo 'pi:groundlight' | sudo tee userconf.txt 
sudo umount /mnt/rpi 

# Fourth step: Run the QEMU emulator
# We need to resize the image to 4GB first (just for the SDK image--should be configurable later)
# since the virtualizer does not accept raw images whose sizes are not powers of 2. 
cd ${ROOT_DIR}
sudo qemu-img resize "$IMAGE_FILE" 4G
sudo qemu-system-aarch64 \
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
