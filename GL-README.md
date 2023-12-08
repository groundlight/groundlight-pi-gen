# Groundlight' Monitoring Notification Server (MNS) as a Raspberry Pi Appliance

This repo builds the OS image for a Groundlight MNS appliance running on Raspberry Pi hardware.

Use this repo to build the `.img` file which gets burned to an SD card.  When that SD card is booted on the Raspberry Pi, 
it runs the [Groundlight Monitoring Notification Server](https://github.com/groundlight/monitoring-notification-server).
The MNS provides a simple GUI to configure a Groundlight detector, grab images from it, and send notifications when
appropriate.

This build system is based on [pi-gen](https://github.com/RPi-Distro/pi-gen).  Refer to its [original README](/README.md) for how everything works.  The (`glmns-config`)[glmns-config] file is the key source of control.  (What is called "config" in the original.)
Also note that we're tracking the `arm64` branch, not main.  (If we build off the main branch, we hit [an issue with missing `arm/v8` docker images](https://github.com/groundlight/monitoring-notification-server/issues/39) and likely others, because we make these funky machines with a 64-bit kernel, but 32-bit applications.)


## Building Images

You should really build this on an ARM system (e.g. an m7g instance in ec2).  
You _can_ build this on an x86 instance, but it will take ~3x longer, and it's not fast to start with.

### Building directly

On the appropriate machine, run:

```
./dobuild.sh
```

This has code for both 
- **local builds** which are faster, but require sudo, and maybe leak resources in a way that require rebooting the build machine.
- **docker builds** which are slower, but don't require sudo, and don't leak resources.

To re-use the cache from docker builds, run

```
CONTINUE=1 ./dobuild.sh
```

### Troubleshooting

To start over try

```
./dobuild.sh CLEAN=1
```

**Unmount errors** - try `sudo mv work deleteme-work`

## Using the images

After ~10 minutes, and then look in the `deploy/` for a file with a name like
`image_2023-12-06-GroundlightMNS-sdk-qemu.img.xz` which will be ~1GB for now.
(See the `COMPRESSION_LEVEL` setting in (`glmns-config`)[glmns-config] to trade speed vs size.)

Copy this to your laptop, and then you can burn it to an SD card using the [Raspberry Pi Image](https://github.com/raspberrypi/rpi-imager).

TODO: figure out how to use them inside `qemu`.
TODO: set up some tests inside `qemu` that things are working.
TODO: write those tests into CI/CD actions.


## What's up with this file?

This file is called `GL-README.md` and is elevated to the github repo homepage by a symlink `.github/README.md`.