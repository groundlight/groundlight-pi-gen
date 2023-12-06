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

Wait ~10 minutes, and then look in the `deploy/` for a file with a name like
`image_2023-12-06-GroundlightNMS-sdk-qemu.img.xz` which will be ~1GB for now.
(See the `COMPRESSION_LEVEL` setting in (`config`)[config] to trade speed vs size.)

Copy this to your laptop, and then you can burn it to an SD card using the [Raspberry Pi Image](https://github.com/raspberrypi/rpi-imager).

