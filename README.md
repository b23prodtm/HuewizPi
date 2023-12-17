# HuewizPi
  A home access point to figure out how to manage lights -Hue-ZigBee- and bridging internet of things
(IoT) over home network (wifi-box)

  [![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/b23prodtm/HuewizPi)
  
## Node Package Manager

  This project depends on npmjs [balena-cloud-apps](https://www.npmjs.com/package/balena-cloud-apps). Please call
  `npm link balena-cloud-apps && npm update`
  whenever the system complains about `balena_deploy` not found.
After npm install succeeded, HuewizPi can be dbuilt and optionally deployed to the device

### Update BALENA_ARCH dependent files

When you make changes to `docker*.template` files and environment `*.env` files, you can apply changes that the CPU architecture depends on. To do so, run deployment scripts `balena_deploy --nobuild` before to push packages:
``` Updates armhf files
./deploy.sh 1 --local [CTRL+C]
```
``` Updates aarch64 files
./deploy.sh 2 --local [CTRL+C]
```
```  Updates x86_64 files
./deploy.sh 3 --local [CTRL+C]
```

### Updating Docker service image (Dockerfile.template)

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

### Deploy to balena
Update balena apps after committing changes `git commit -a && git push`
  `. deploy.sh`

### Deconz Raspbee container
[Read dconz community README](https://github.com/deconz-community/deconz-docker#readme) Serial BT UART must be swapped to GPIO.
  > Define DT overlays
"pi3-miniuart-bt"
In devices fleet configuration dashboard, *Define DT overlays "pi3-miniuart-bt"*

# Usage
Basically, this script's made for linux machines that have got a wireless card or chipset and an ethernet interface connected to the internet. Following the wizard script to install hostapd and its dependencies on the machine :
```
scripts/start.sh optional:	[-c,--client]
    required:	<priv_interface> <priv-network-x.x.x.0/len>
		required:	<wan-network-x.x.x.0/len> <wan-interface>
		user input:	[ssid passphrase [mode] [country_code channel]
		user input:	[dns1 dns2]
		w/ wan wlan1:	[wan_ssid wan_passphrase]
		optional:	[net-range-start net-range-end]
		optional:	[priv-network-ipv6/mask-length wan-network-ipv6/mask-length]
		optional:	[dns1-ipv6 dns2-ipv6]
```

Here follows a sample command line of a host access point acting as a router on the local network 192.168.0.0/24 (ISP router setup). Routing Broadband Internet Connection (eth0/wlan1) via Wireless Card (wlan0): ip adresses 10.0.1.x) and open a HomeWifiNet WPA-PSK secured Wifi network, try :

  ```scripts/start.sh wlan0 10.0.1.0/24 192.168.0.0/24 eth0 HomeWifiNet 1ApassWoRd a US 36```

For instance, use channel 6 for b/g/n 2,4GHz or channel 36 for ac 5GHz. Usually set to an automatic channel selection [0] doesn't work with some wifi chipsets (see manufacturer's specifications).

The host must have access to the Internet in order to share its connection to the Wireless clients. A reboot is needed to allow system services to restart in the correct order (system-resolved isc-dhcp-server hostapd).

### Flow diagram
```flow
wifi=>start: wifi-spot
net=>operation: Wifi network (wifi-box)
cond=>condition: Device connected ?
cond2=>condition: Gateway found ?
hb=>operation: Homebridge Hue Plugin
zb=>end: Light bulb on/off

wifi->net->cond->hb->cond2
cond(yes)->hb
cond(no)->net
cond2(yes)->zb
cond2(no)->hb
```

### DNS probe URL on the internet
If you encounter difficulties by connecting to the internet through thewifi hotspot, it's because of an incorrect DNS setup.
Run the folloying command on the host machine, it should return a valid dns from your ISP, in a (docker) shell instance:

   ```systemd-resolve --status```

If you don't know the DNS IP addresses of your ISP, ask your administrator for them or try to resolve them with:

   ```nslookup ns1.your-isp.com ns2.your-isp.com```

Then add them to your home wifi network, either reset environment variable, e.g. ns1.orange.fr, ns2.orange.fr:

   ```DNS1=80.10.201.224 DNS2_IPV6=2a01:cb14:2040::1#53  
   scripts/start.sh wlan0 10.0.1.0/24 192.168.1.0/24 eth0 HomeWifiNet OneWPAssword a FR 36 $DNS1 $DNS1 "NOT_SSID" "NOT_PASS" $DNS2_IPV6 $DNS2_IPV6```

### Fixed IP address client
Host Access Point's able to define a fixed IP for a specific host. To list the current leases in DHCP service, run dhcp-lease-list :
 ```dhcp-lease-list
To get manufacturer names please download http://standards.ieee.org/regauth/oui/oui.txt to /usr/local/etc/oui.txt
Reading leases from /var/lib/dhcp/dhcpd.leases
MAC                IP              hostname       valid until         manufacturer        
===============================================================================================
b8:...:f2  10.0.1.37    clientmachine   2018-07-20 13:37:49 -NA-  
```
You can assign a fixed IP to any host with the following script :
 ```scripts/init.d/init_dhcp_serv.sh --leases clientmachine 5```
A few minutes later, *clientmachine* will be permanently fixed to the IP address 10.0.1.5 instead of 10.0.1.37.

### Troubleshooting
  - I cannot access the internet after the script returns from reboot.
  Is that maybe linked to an error in the DHCPd process ?

  > Choose either way: if you can connect to the host machine with ssh or from host keyboard, restart the DHCP server : ```sudo netplan apply && sudo systemctl restart isc-dhcp-server```, check status then ```sudo systemctl status isc-dhcp-server```from host machine (which runs hostapd).

  - The Wifi machines never get an IP Address on 10.233.1.x after they connected to the private Wifi network, or they have to wait for several minutes to get an answer.

  > Obviously the DHCP server (isc-dhcp-server) is getting a lot of DHCPREQUEST and reading leases from _/var/lib/dhcp/dhcpd.leases_ takes some time. Remove obsolete hosts from this _lease_ file.

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
