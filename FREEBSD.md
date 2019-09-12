# OpenZWave FreeBSD ```iocage``` Instructions

Instructions for getting [```OpenZWave```](http://www.openzwave.com/) and control panel running inside of FreeBSD and FreeNAS jails. Precursor to getting [Home Assistant](https://www.home-assistant.io/) running inside of a jail.

Requires a small amount of command line knowledge. There is no one liner that is in vogue right now like: ```curl -sSL https://install.pi-hole.net | bash```. Read and comprehend the commands so I don't slip in a ```rm -rf```.

## ```iocage``` setup

On jail host:

    curl -OL https://github.com/jed-frey/FreeNAS-devops/archive/origin/freenas-11.2.zip
    unzip freenas-11.2.zip 
    cd FreeNAS-devops-origin-freenas-11.2/
    make cage NAME=ozw IFACE=igb0 PREFIX=22 IP=172.16.0.50

Where ```NAME```, ```IFACE```, ```PREFIX```, and ```IP``` are jail name, network interface, network prefix and jail IP address, respectively.

Pass through /dev so OZW can access the USB devices:

    iocage set allow_mount_devfs=1 devfs_ruleset=6 ozw
    iocage restart ozw

## Jail setup

Drop into jail console, use jail ```NAME``` from above.

    iocage console ozw

From jail console:

    pkg install -y git
    # The package management tool is not yet installed on your system.
    # Do you want to fetch and install it now? [y/N]: y
    git clone https://github.com/jed-frey/open-zwave-control-panel.git
    cd open-zwave-control-panel
    git submodule init
    git submodule update
    cat requirements.pkg | xargs pkg install -y
    # Change -j# to the number of cores on your machine.
    gmake -j8

    cp -r open-zwave/config ./
    ./ozwcp 

- Navigate to the jail IP (specified above) port 8090.
  - [http://ozw.local:8090](http://ozw.local:8090) if you have mDNS setup on your local machine.
- Use ```/dev/cuaU#``` as device name. (Specific device depends on your setup)
- Do **not** check USB.
- Click Initialize.


# Tested with:

- [Aeotec Z-Wave USB Stick](https://aeotec.com/z-wave-usb-stick)
  - Gen2
  - Gen5
- FreeBSD 11.1-STABLE #0 r321665+de6be8c8d30(freenas/11.1-stable): Tue Feb 20 02:38:09 UTC 2018
  root@gauntlet:/freenas-11-releng/freenas/_BE/objs/freenas-11-releng/freenas/_BE/os/sys/FreeNAS.amd64 
- ```FreeBSD hass-1 12.0-RELEASE FreeBSD 12.0-RELEASE r341666 GENERIC  amd64```

