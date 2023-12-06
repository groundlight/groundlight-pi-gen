# Groundlight Network Monitoring Server (NMS) on Raspberry Pi

This repo builds an OS image for Rasperry Pi that comes with the Groundlight NMS.

This build system is based on [pi-gen](https://github.com/RPi-Distro/pi-gen).  Refer to its [README](PI-GEN-README.md)

## Building

You should really build this on an ARM system (e.g. an m7g instance in ec2).  
You _can_ build this on an x86 instance, but it will take ~3x longer, and it's not fast to start with.

On the appropriate machine, run:

```
time sudo ./build.sh
```

Wait ~10 minutes, and then look in the `work/GroundlightNMS/export-image/` for a file with a name like
`2023-12-06-GroundlightNMS-lite-qemu.img`, which should be around 3GB at current.

Copy this to your laptop, and then you can burn it to an SD card using the [Raspberry Pi Image](https://github.com/raspberrypi/rpi-imager).

