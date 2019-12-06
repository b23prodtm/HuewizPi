#!/usr/bin/env bash
[ -z ${scriptsd} ] && export scriptsd=../$(echo $0 | awk 'BEGIN{FS="/";ORS="/"}{ for(i=1;i<NF;i++) print $i }')
[ ! -f ${scriptsd}../.hap-wiz-env.sh ] && bash -c "python ${scriptsd}../library/hap-wiz-env.py $*"
source ${scriptsd}../.hap-wiz-env.sh
source ${scriptsd}dns-lookup.sh
yaml='02-hostap.yaml'
clientyaml='01-cliwpa.yaml'
nameservers_def="${NET}.1"
nameservers6_def="${NET6}1"
nameservers=''
nameservers6=''
NP_ORIG=/usr/share/netplan && sudo mkdir -p $NP_ORIG
slogger -st netplan "disable cloud-init"
sudo mv -fv /etc/netplan/50-cloud-init.yaml $NP_ORIG
echo -e "network: { config: disabled }" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
if [ -f /etc/init.d/networking ]; then
    echo -e "${MARKER_BEGIN}
auto lo
face lo inet loopback

allow-hotplug eth0
iface ${INT} inet dhcp
 network ${INTNET}.0
${MARKER_END}" | sudo tee /etc/network/interfaces
else
  echo -e "${MARKER_BEGIN}
network:
  version: 2
  renderer: networkd
  ethernets:
    ${INT}:
      dhcp4: yes
      dhcp6: yes
${MARKER_END}" | sudo tee /etc/netplan/$yaml
fi
while [ "$#" -gt 0 ]; do case $1 in
  -r*|-R*)
    if [ -f /etc/init.d/networking ]; then
      sudo sed -i ${MARKERS}d /etc/network/interfaces
    else
      # ubuntu server
      slogger -st netplan "move configuration to $NP_ORIG"
      sudo mv -fv /etc/netplan/* $NP_ORIG
      slogger -st netplan "reset configuration to cloud-init"
      sudo mv -fv $NP_ORIG/50-cloud-init.yaml /etc/netplan
      sudo rm -fv /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
    fi
    return;;
  --dns)
      nameservers_def=''
      nameservers=$(nameservers $nameservers $2)
      shift;;
  --dns6)
      nameservers6_def=''
      nameservers6=$(nameservers $nameservers6 "'$2'")
      shift;;
  --wifi)
    if [ -f /etc/init.d/networking ]; then
      echo -e "${MARKER_BEGIN}
allow-hotplug wlan0
iface wlan0 inet dhcp
${MARKER_END}" | sudo tee -a /etc/network/interfaces
      sudo /etc/init.d/networking restart
      sudo ${scriptsd}init.d/init_wpa_ctl.sh
    else
      slogger -st netplan "/etc/netplan/$clientyaml was created"
        echo -e "${MARKER_BEGIN}
network:
  version: 2
  renderer: networkd
  wifis:
    wlan0:
      dhcp4: yes
      dhcp6: yes
      access-points:
        \"$2\":
          password: \"$3\"
${MARKER_END}" | sudo tee /etc/netplan/$clientyaml
    fi
    shift;shift
    ;;
  -h*|--help)
    echo -e "Usage: $0 [-r] [[--wifi <SSID> <passphrase>] [-b, --bridge]] [--dns <ipv4> [--dns6 '<ipv6>']
    Initializes netplan.io networks plans and eventually restart them.
    -r
      Removes bridge interface
    --wifi
      Render a Wifi interface wlan0
    --bridge
      Render a bridge connection between ${INT} and wlan0, skipping private network ${NET}.0 (should be used with --wifi)
    --dns
      Add a public custom DNS address (e.g. --dns 8.8.8.8 --dns 9.9.9.9)
    --dns6
      Add a public custom DNS ipv6 address, (e.g. --dns6 2001:4860:4860::8888 --dns6 2001:4860:4860::8844)"
          exit 1;;
   -b*|--bridge)
   if [ -f /etc/init.d/networking ]; then
   # ubuntu < 18.04
   echo -e "${MARKER_BEGIN}
# Bridge setup
auto br0
iface br0 inet dhcp
 address 10.33.0.1
 network 10.33.0.0
 netmask 255.255.255.0
 nameservers $nameservers
bridge_ports wlan0 ${INT}
${MARKER_END}" | sudo tee -a /etc/network/interfaces
     slogger -st brctl "share the internet wireless over bridge"
     sudo brctl addbr br0
     sudo brctl addif br0 eth0 wlan0
   else
     # new 18.04 netplan server (DHCPd set to bridge)
     slogger -st netplan "/etc/netplan/$yaml was created"
     echo -e "${MARKER_BEGIN}
  bridges:
    br0:
      dhcp4: yes
      dhcp6: yes
      addresses: [10.33.0.1/24, '2001:db8:1:46::1/64']
      nameservers:
        addresses: [${nameservers},${nameservers6}]
      interfaces:
        - wlan0
        - eth0
${MARKER_END}" | sudo tee -a /etc/netplan/$yaml
   fi;;
   *);;
esac; shift; done
nameservers=$(nameservers $nameservers $nameservers_def)
nameservers6=$(nameservers $nameservers6 "'${nameservers6_def}'")
slogger -st network "add wifi network"
if [ -f /etc/init.d/networking ]; then
    sudo sed -i s/"iface wlan0 inet dhcp"/"\\n\
iface wlan0 inet manual\\n\
 address ${NET}.1\\n\
 network ${NET}.0\\n\
 netmask ${MASK}\\n\
 nameservers ${nameservers}"/ /etc/network/interfaces
    cat /etc/network/interfaces | grep -A4 "iface wlan0"
else
    sudo sed -i /"password:"/a"\\
      addresses: [${NET}.1/24, '${NET6}1/64']\\n\
      nameservers:\\n\
        addresses: [${nameservers},${nameservers6}]" /etc/netplan/$clientyaml
    sudo sed -i /"wlan0:"/,/"${MARKER_END}"/s/yes/no/g /etc/netplan/$clientyaml
    cat /etc/netplan/$clientyaml | grep -A8 "wlan0"
fi
