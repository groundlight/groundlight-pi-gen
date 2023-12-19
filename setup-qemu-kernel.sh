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
sudo apt install -y \
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
ARCH=${ARCH} CROSS_COMPILE=/bin/aarch64-linux-gnu- make -j${NUM_CORES}

cp arch/${ARCH}/boot/Image ${ROOT_DIR}