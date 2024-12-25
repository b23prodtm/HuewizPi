# HuewizPi
[![Hue WIZ PI](https://circleci.com/gh/b23prodtm/HuewizPi.svg?style=shield)](https://app.circleci.com/pipelines/github/b23prodtm/HuewizPi)
  A home access point to figure out how to manage lights -Hue-ZigBee- and bridging internet of things
(IoT) over home network (wifi-box)

# Quickstart (easy)
After deployment, it's available at https://'''Machine-IP-or-URL''':8123 as the local Home Assistant access point.

A dashboard appears and it can manage your home devices as if you had installed a real home nest or the homekit.

Buy a [Zigbee gateway](https://phoscon.de/en/raspbee2/) from Phoscon and other manufacturers to support individual Lights and devices.
Generally uses the UART port as AMA0 in RPi but the [Deconz dongle](https://phoscon.de/en/conbee2/) uses USB0.

Add to [Zigbee Home Automation](https://www.home-assistant.io/integrations/zha)

## Deploy to balena
Browse to balena hub of apps [Huewiz-pi at balenaHub]([www/balena.io](https://hub.balena.io/apps/1951536/huewiz-pi)) or one-click

  [![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/b23prodtm/HuewizPi)

If you forked it and want to be committing changes, use `. deploy.sh` to deploy to your own fleet or build new applications

## Passbolt
Added [Passbolt community edition](https://www.passbolt.com/ce/docker)
### Step 1. Configure environment variables in docker-compose-ce.yaml file to customize your instance.

Notice: By default the docker-compose.yaml file is set to latest. We strongly recommend changing that to the tag for the version you want to install.

The APP_FULL_BASE_URL environment variable is set by default to https://passbolt.local, using a self-signed certificate.

Update this variable with the server name you plan to use. You will find at the bottom of this documentation links about how to set your own SSL certificate.

You must configure also SMTP settings to be able to receive notifications and recovery emails. Please find below the most used environment variables for this purpose:

Variable name	Description	Default value
```
EMAIL_DEFAULT_FROM_NAME	 From email username	'Passbolt'
EMAIL_DEFAULT_FROM	From email address as server account	'user@mailersend.net'
EMAIL_TRANSPORT_DEFAULT_HOST	Server hostname	'localhost'
EMAIL_TRANSPORT_DEFAULT_PORT	Server port	25
EMAIL_TRANSPORT_DEFAULT_USERNAME	Username for email server auth	'user@mailersend.net'
EMAIL_TRANSPORT_DEFAULT_PASSWORD	Password for email server auth	'password'
EMAIL_TRANSPORT_DEFAULT_TLS	Set true for	STARTTLS
```
For more information on which environment variables are available on passbolt, please check the passbolt environment variable reference.


### Step 2. Create first admin user

```
$ balena ssh <device-uuid> passbolt
```
for instance, whithin SSH web terminal, must be run by the user www-data:
```
$ su -s /bin/bash -c "bin/cake \
                                passbolt register_user \
                                -u <your@email.com> \
                                -f <yourname> \
                                -l <surname> \
                                -r admin" www-data
```
If it's an update, the cake's migration command create or update the database tables:

```
$ balena ssh <device-uuid> passbolt /usr/share/php/passbolt/bin/cake \
                                                                passbolt migrate
```

Set ***APP_FULL_BASE_URL*** to https://your-devices-hostname/ and browse to this URL to start setup.
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
