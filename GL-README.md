# Groundlight Pi-Gen: OS images for Raspberry PI with Groundlight Tools

This repo builds OS images for Groundlight tools and applications, including the bare python SDK, 
and the Monitoring Notification Server (MNS).  The OS images are available in the [releases](https://github.com/groundlight/groundlight-pi-gen/releases) and can be installed with [Raspberry Pi imager](https://www.raspberrypi.com/software/).

There are several different images available, depending on your needs, from smallest to largest:

- **`sdk-only`** - A minimal image with just the Python SDK installed.  This is the smallest image, and is suitable for running the SDK on a Raspberry Pi Zero W.  It is also suitable for running the SDK on a Raspberry Pi 3 or 4, if you don't need the GUI.
- **`mns-headless`** - an image with the [Groundlight Monitoring Notification Server (MNS)](https://github.com/groundlight/monitoring-notification-server) installed for headless use.  "Headless" means it runs the server, which serves HTML pages, but has no browser or GUI to use it from.  You need to connect from another machine to use MNS.  The MNS provides a simple way to configure cameras, Groundlight detectors, and send notifications conditions are met.
- **`full`** - an image with the Groundlight MNS installed, and a desktop GUI with a browser.  This is appropriate for a Raspberry Pi which will have a screen attached to it.
- **`edge`** - Not available yet.  The Edge Endpoint server is still too resource hungry to run on a Raspberry Pi.  Please [leave a comment](https://github.com/groundlight/groundlight-pi-gen/issues/5) if you'd like to use this.


## Source Code

This build system is based on [pi-gen](https://github.com/RPi-Distro/pi-gen).  Refer to its [original README](/README.md) for how everything works.  The (`gl-config`)[gl-config] file is the key source of control.  (What is called "config" in the original.)

Note that we're tracking the `arm64` branch, not main.  (If we build off the main branch, we hit [an issue with missing `arm/v8` docker images](https://github.com/groundlight/monitoring-notification-server/issues/39) and likely others, because we make these funky machines with a 64-bit kernel, but 32-bit applications.)


## Building Images

We recommend building on an ARM machine (like an m7g instance in ec2).  You can build on an x86 machine, but it will take significantly longer, and it's not fast to start with.  Building on ARM-powered Macs seems like a good idea, and "should" work, but isn't tested.

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

### But it's so SLOW!

A full build can take 10s of minutes. But partial builds get cached in a docker volume and will speed things up dramatically. Beware that the caches don't get invalidated automatically or sensibly, so it will lead to problems as you're working on it.

Also, the best way to speed things up is to skip building stages you don't care about (e.g. `stage3` the desktop environment).  You can do this without editing the `glmns-config` file with:

```
touch stage3/SKIP
```

Also, you can get a bit of a boost by skipping export of the `sdk` variant image:

```
touch stage-gl1/SKIP_IMAGES
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
(See the `COMPRESSION_LEVEL` setting in (`gl-config`)[gl-config] to trade speed vs size.)

Copy this to your laptop, and then you can burn it to an SD card using the [Raspberry Pi Image](https://github.com/raspberrypi/rpi-imager).

TODO: set up some tests inside `qemu` that things are working.
TODO: write those tests into CI/CD actions.


## Running the Raspberry Pi Image with QEMU 
To emulate the Raspberry Pi image with QEMU, we will first need to install the Linux kernel for QEMU on the 
host machine and install other necessary packages required for QEMU to work. To do this, run 

```shell 
chmod +x setup-qemu-kernel.sh 
./setup-qemu-kernel.sh 
```

This needs to be done only once. It will download a linux kernel of 36MB. 

To run the emulator, go ahead and run 

```shell 
chmod +x rpistart.sh 
./rpistart.sh -i <absolute-path-to-image>
```

The image path must be absolute and it needs to be decompressed. You can decompress the image by runnning 

```shell
xz -d <path-to-compressed-image> 
```

This will start the emulator. You can SSH into it by running 

```shell
ssh -l pi localhost -p 2222
```

By default, the username and password are `pi` and `raspberry` respectively. You can overrride these by setting 
the following environment variables before running the `rpistart.sh` script. 

```shell
export USERNAME=<username>
export PASSWORD=<password>
```


## What's up with this file?

This file is called `GL-README.md` and is elevated to the github repo homepage by a symlink `.github/README.md`.