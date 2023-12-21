# HuewizPi
  A home access point to figure out how to manage lights -Hue-ZigBee- and bridging internet of things
(IoT) over home network (wifi-box)

# Quickstart (easy)
After deployment, it's available at https://<Machine-IP>:8123 as the local Home Assistant access point.

A dashboard appears and it can manage your home devices as if you had installed a real home nest or the homekit. 

Buy a [Zigbee gateway](https://phoscon.de/en/raspbee2/) from Phoscon and other manufacturers to support individual Lights and devices. 
Generally uses the UART port as AMA0 in RPi but the [Deconz dongle](https://phoscon.de/en/conbee2/) uses USB0.

Credits to [Home-Assistant.io integrations](https://www.home-assistant.io/integrations/)

## Deploy to balena
Browse to balena hub of apps [Huewiz-pi at balenaHub]([www/balena.io](https://hub.balena.io/apps/1951536/huewiz-pi)) or one-click

  [![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/b23prodtm/HuewizPi)

If you forked it and want to be committing changes, use `. deploy.sh` to deploy to your own fleet or build new applications
  
## Deconz Raspbee container (alpha)
[Read dconz community README](https://github.com/deconz-community/deconz-docker#readme) Serial BT UART must be swapped to GPIO.
In devices fleet configuration dashboard, *Define DT overlays `pi3-miniuart-bt`

### Wireless Access Point
> WAP in alpha version
Basically, this script's made for linux machines that have got a wireless card or chipset and an ethernet interface connected to the internet.

The host must have access to the Internet in order to share its connection to the Wireless clients. A reboot is needed to allow system services to restart in the correct order (system-resolved isc-dhcp-server hostapd).

### Node Package Manager

  This project depends on npmjs [balena-cloud-apps](https://www.npmjs.com/package/balena-cloud-apps). Please call
  `npm link balena-cloud-apps && npm update`
  whenever the system complains about `balena_deploy` not found.
After npm install succeeded, HuewizPi can be dbuilt and optionally deployed to the device

### Update BALENA_ARCH dependent files

When you make changes to `docker*.template` files and environment `*.env` files, you can apply changes that the CPU architecture depends on. To do so, run deployment scripts `balena_deploy --nobuild` before to push packages:
``` Updates armhf files (ARM v7 32 bits kernel)
./deploy.sh 1 --local [CTRL+C]
```
``` Updates aarch64 files (ARM v8 64 bits kernel
./deploy.sh 2 --local [CTRL+C]
```
``` Updates x86_64 files (AMD/Intel 64 bits Cores)
./deploy.sh 3 --local [CTRL+C]
```

## Updating
Docker service image (Dockerfile.template)

A new service image can be build
- Check values in `${BALENA_ARCH}.env`,
========================================================
| Node Machine   | `BALENA_MACHINE_NAME` | `BALENA_ARCH`
| ------------     ---------------------   -------------
| Raspberry Pi 3 | raspberrypi3           | armhf
| Raspberry Pi 4 | raspberrypi3-64       | aarch64
| Mini PC        | intel-nuc             | x86_64
========================================================
- Run `./deploy.sh [BALENA_ARCH] --nobuild`
  You can select 1:armhf, 2:aarch64 or 3:x86_64 as the target machine CPU
- You choose to build FROM a balenalib base image as set in Dockerfile.template, then type `0` or `CTRL-C` to exit the script
- All template data filters copy to Dockerfile.aarch64, Dockerfile.armhf and Dockerfile.x86_64

### Copyright 2018 www.b23prodtm.info - https://github.com/b23prodtm/HuewizPi

Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
