#!/bin/bash
# This is a tool for compiling and replacing the raspberry pi kernel
# author: why

# The path to the folder used to build the kernel
#workspace="./"
kernel_path="./linux/"

# The version number of kernel
kernel_version="rpi-5.4.y"

# The number of threads
thread_num="8"

# The path of sd card
boot_path="/dev/sdb1"
root_path="/dev/sdb2"

if [ "$1" == "-h" ] ; then
	echo "usage :"
	echo "	./kpi.sh init (at first time)"
	echo "	./kpi.sh      (if you've already set up the environment)"
elif [ "$1" == "init" ]; then
# 1.Environment set up
## 1.1 install tools
	sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev  &&

## 1.2 mkdir
#	mkdir ${workspace} &&
#	cd ${workspace} &&

# 2.Get kernel and toolchain from github
## 2.1 get kernel
	git clone --depth=1 -b ${kernel_version} https://github.com/raspberrypi/linux.git  &&

## 2.2 get toolchain
	sudo apt install crossbuild-essential-armhf

else
	cd ${kernel_path}  &&
#	cd ~/pi_kernel/linux/ &&
## 3.1 Mount
	umount ${boot_path}
	umount ${root_path}
	mount ${boot_path} /mnt/fat32 &&
	mount ${root_path} /mnt/ext4  &&

## 3.2 Default config
	KERNEL=kernel7  &&
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig  &&

## 3.2 DIY config
#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

# 4.Compile the kernel and dts and modules 
# If you do not change the kernel version or modify the device information, you only need to compile the kernel separately.
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage -j${thread_num}
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules -j${thread_num}
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs

	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs -j${thread_num} &&

# 5.Backup and replace
## Replace kernel

	sudo cp /mnt/fat32/$KERNEL.img /mnt/fat32/$KERNEL-backup.img  &&
	sudo cp arch/arm/boot/zImage /mnt/fat32/$KERNEL.img  &&

## Replace driver trees
	sudo cp arch/arm/boot/dts/*.dtb /mnt/fat32/  &&
	sudo cp arch/arm/boot/dts/overlays/*.dtb* /mnt/fat32/overlays/  &&
	sudo cp arch/arm/boot/dts/overlays/README /mnt/fat32/overlays/  &&


## Repalce modules
	sudo env PATH=$PATH make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=/mnt/ext4 modules_install  &&

#umount sd
	umount /dev/sdb1 &&
	umount /dev/sdb2
fi
