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

## Passbolt configuration
Create first admin user

```$ balena ssh <device-uuid> passbolt su -m -c "/usr/share/php/passbolt/bin/cake \
                                passbolt register_user \
                                -u <your@email.com> \
                                -f <yourname> \
                                -l <surname> \
                                -r admin" -s /bin/sh www-data
                                ```
It will output a link similar to the below one that can be pasted on the browser to finalize user registration:
```
https://my.domain.tld/setup/install/1eafab88-a17d-4ad8-97af-77a97f5ff552/f097be64-3703-41e2-8ea2-d59cbe1c15bc
```
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
