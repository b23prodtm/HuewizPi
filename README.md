# HapwizPY
 Host access point Wizard script for Debian/Ubuntu

# Usage
Basically, this script's made for linux machines that have got a wireless card or chipset and an ethernet interface connected to the internet. Following the wizard script to install hostapd and its dependencies on the machine : ```scripts/hap-wiz-bionic.sh [-c,--client] <priv-network-x.x.x.0/len> <wan-network-x.x.x.0/len> <wan-interface> [ssid passphrase [mode] [country_code channel] [net-range-start net-range-end] [priv-network-ipv6/mask-length wan-network-ipv6/mask-length]]```

Here follows a sample command line of a host access point acting as a router on the local network 192.168.0.0/24 (ISP router setup). Routing Broadband Internet Connection from  Ethernet (eth0) via Wireless Card (wlan0: ip adresses 10.0.1.x) and open a HomeWifiNet WPA-PSK secured Wifi network, try :

  ```scripts/hap-wiz-bionic.sh 10.0.1.0/24 192.168.0.0/24 eth0 HomeWifiNet OneWPAssword a US 36```

For instance, use channel 6 for b/g/n 2,4GHz or channel 36 for ac 5GHz. Usually set to an automatic channel selection [0] doesn't work with some wifi chipsets (see manufacturer's specifications).

The host must have access to the Internet in order to share its connection to the Wireless clients. A reboot is needed to allow system services to restart in the correct order (system-resolved isc-dhcp-server hostapd).

# Copyright 2018 www.b23prodtm.info

Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
