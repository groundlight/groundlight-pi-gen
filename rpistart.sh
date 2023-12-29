#!/bin/bash 



# This script will assume that you've already built the linux kernel for QEMU and copied 
# the kernel to the root directory. In addition, it will assume that you've already generated 
# the Raspberry Pi OS image and decompressed it. 
# To use this script, run the following command 
# 
# $ ./rpistart.sh -i <img-file-path>
# 
# <img-file-path> needs to be an absolute path: 
# Ex. /home/ubuntu/groundlight-pi-gen/deploy/image_2023-12-19-GroundlightPi-desktop-qemu.img
# 
# If you don't want to use the default login credentials (username=pi, password=raspberry), you
# can set the USERNAME and PASSWORD as environment variables before running this script.
# 
# $ export USERNAME=<username>
# $ export PASSWORD=<password>
# $ ./rpistart.sh -i <img-file-path>
# 


set -ex 


cd "$(dirname "$0")"

ROOT_DIR=$HOME
IMAGE_FILE=""
KERNEL_IMAGE=$ROOT_DIR/Image
NUM_RPI_CPU_CORES=4



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
        echo "Error: Non-numeric value detected: $1"
        exit 1
    fi
}

# Check that the provided path exists, is absolute and ends with "qemu.img"
if [ ! -f "$IMAGE_FILE" ]; then 
    echo "Invalid Raspberry Pi OS image: '$IMAGE_FILE'"
    exit 1
elif [[ "$IMAGE_FILE" != /* ]]; then 
    echo "The image path is not absolute: '$IMAGE_FILE'"
    exit 1
elif [[ "$IMAGE_FILE" != *qemu.img ]]; then
    echo "The image does not have the expected 'qemu.img' suffix: '$IMAGE_FILE'"
    echo "You probably forgot to decompress the image by running 'xz -d <*.img.xz>'"
    exit 1
fi 


# Validate that the QEMU kernel image path
if [ ! -f "$KERNEL_IMAGE" ]; then 
    echo "Invalid path for the Linux kernel for QEMU: '$KERNEL_IMAGE'. Make sure to run './setup-qemu-kernel.sh' first."
    exit 1 
fi 

# Mount the image for enabling SSH and configuring username and password and 
# accessing the files within the image. 
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
if findmnt -M /mnt/rpi > /dev/null; then
    echo "/mnt/rpi is already mounted."
else
    sudo mount -o loop,offset=${OFFSET} ${IMAGE_FILE} /mnt/rpi
fi

USERNAME=${USERNAME:-"pi"}
PASSWORD=${PASSWORD:-"raspberry"}


# Create an 'ssh' file and 'userconf.txt' in the mounted directory. We will put the 
# username and password in 'userconf.txt', which will be used as the default login
# credentials. 
if [ -d "/mnt/rpi" ]; then
    cd /mnt/rpi
    sudo touch ssh
    sudo rm -f userconf.txt > /dev/null

    # Create a hashed password with openssl. The -6 option instructs OpenSSL 
    # to use Sha512. This applies salting (i.e., the hash will be different every time).
    # https://www.openssl.org/docs/man1.0.2/man1/passwd.html#:~:text=The%20passwd%20command%20computes%20the,or%20from%20the%20terminal%20otherwise.
    HASHED_PASSWORD=$(openssl passwd -6 "${PASSWORD}")
    echo "${USERNAME}:${HASHED_PASSWORD}" | sudo tee userconf.txt > /dev/null
else
    echo "Image not mounted to /mnt/rpi"
    exit 1
fi

cd $ROOT_DIR
sudo umount /mnt/rpi 

# Run the QEMU emulator

# - kernel: This is the path to the QEMU kernel downloaded in step 2
# - append: Providing the boot arguments directly to the kernel, telling it where to find the 
#           root filesystem and what type it is. 
# - cpu/m: This sets the CPU type and RAM to match a Raspberry Pi
# - machine: This sets the machine we are emulating. `virt` refers to a generic, virtualized 
#           machine type provided by QEMU
# - smp: Specifies the number of CPU cores
# - drive: Defines a drive with the given parameters. 
# - device: Attaches the drive to the VM using a VirtIO block device. bootindex=0 means it will 
#          be the first boot device. 
# - netdev: Sets up a user-mode network backend with ID mynet. It also sets up SSH (forwarding
#          TCP connections from host port 2222 to guest port 22).
# - monitor: Opens a QEMU monitor console accessible via Telnet on port 5555. The VM will not
#          wait for a monitor connection before starting. 
sudo qemu-system-aarch64 \
        -machine virt \
        -cpu cortex-a72 \
        -smp $NUM_RPI_CPU_CORES \
        -m 4G \
        -kernel $KERNEL_IMAGE \
        -append "root=/dev/vda2 rootfstype=ext4 rw panic=0 console=ttyAMA0 autologin" \
        -drive format=raw,file=$IMAGE_FILE,if=none,id=hd0,cache=writeback \
        -device virtio-blk,drive=hd0,bootindex=0 \
        -netdev user,id=mynet,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=mynet \
        -monitor telnet:127.0.0.1:5555,server,nowait \
        -nographic 
