# Installation of ACER AAEON Boxer-6639-A4-1010

## Hardware
* CPU:
* RAM:
* STORAGE: 

## Software
The installation for the ACER AAEON Boxer-6639-A4-1010 comes with two rootfs partitions installed on separate disk and a data partition mirrored (RAID 1) over the two disks.

The rootfs includes Linux kernel and a custom Linux distribution while the data partition is mounted to `/data`.

## Initial installation
Begin with connecting a monitor and keyboard to the Edge gateway, and plug in the USB installation media in one of the USB 3.0 ports.

### Disable Intel® Rapid Storage Technology (RST)
1. Start up the Edge gateway and hit CTRL+i to enter the RST menu
2. Delete any existing RAID configuraition. Save and exit

### Set the Edge gateway to boot from USB
3. Hit `ESC` to enter BIOS setup
4. In the BIOS setup, navigate to the `BOOT` section. Set the "Boot Option #1" to the USB device. Save and exit the BIOS setup

### Installation
5. The installation will start automatically, but will halt early on in the process. This is to be able to fix and clean up any installation problems if you run the installation again. Hit CTRL+d to proceed.
6. The installation will continue to setup and install all partitions. 
7. When the installation is complete, remove the USB stick and hit `Enter`. As the Edge gateway restarts, hit the `ESC` key again to enter the BIOS setup.
8. In the BIOS setup, navigate to the `BOOT` section. Set the "Boot Option #1" to `[UEFI OS]`. Save and exit the BIOS setup.

> As the Edge gateway is starting up, it will setup the data mirroring. This can take up to 20 minutes. Services such as Docker and the microServiceBus Node agent will not start until the process is complete.

9. Open a browser and navigate to https://microservicebus.com. Navigate to the `/nodes` page and wait until the Node is ready to claim (again, might take up to 20 minutes).
10. Claim the Node, and wait until it's online in microServiceBus.com
11. Through the `Action` menu, select `Device`. Click the `Firmware` tab and hit the `SET TO BOOT` button. The Edge gateway will now restart.

> This step is neccesary to enable the RAID/mirroring on the second boot partition.

12. Make sure the Edge gateway comes online again in the microServiceBus.com portal

## Update firmware
1. Open a browser and navigate to https://microservicebus.com. Navigate to the `/nodes` page.
2. Through the `Action` menu, select `Device`. Click the `Firmware` tab and hit the `Update firmware` button. The Edge gateway will now restart.
3. Make sure the Edge gateway comes online again in the microServiceBus.com portal

## Reset installation to initial state
1. Open a browser and navigate to https://microservicebus.com. Navigate to the `/nodes` page.
2. Through the `Action` menu, select `Open terminal`
3. In the terminal type:
```
./usr/bin/remove-raid.sh
```
4.  Plug in the USB installation media in one of the USB 3.0 ports, and restart the device
5. Hit `ESC` to enter BIOS setup
6. In the BIOS setup, navigate to the `BOOT` section. Set the "Boot Option #1" to the USB device. Save and exit the BIOS setup.
7. The installation will start automatically, but will halt early on in the process. Hit CTRL+d to proceed.

> If the installation fails, restart the the device and continue from previous step