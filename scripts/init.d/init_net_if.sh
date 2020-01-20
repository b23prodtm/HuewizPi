#!/usr/bin/env bash
usage="
Usage: $0 [-r] [[--wifi <INTERFACE> <SSID> <passphrase>] [-b, --bridge]] [--dns <ipv4> [--dns6 '<ipv6>']
Initializes netplan.io networks plans and eventually restart them.
-r
  Removes bridge interface
--wifi
  Render a Wifi interface
--bridge
  Render a bridge connection between ${WAN_INT} and ${PRIV_INT}, skipping private network ${PRIV_NETWORK}.0 (should be used with --wifi)
--dns
  Add a public custom DNS address (e.g. --dns 8.8.8.8 --dns 9.9.9.9)
--dns6
  Add a public custom DNS ipv6 address, (e.g. --dns6 2001:4860:4860::8888 --dns6 2001:4860:4860::8844)"
[ -z ${scriptsd} ] && export scriptsd=$(echo $0 | awk 'BEGIN{FS="/";ORS="/"}{ for(i=1;i<NF;i++) print $i }')../
[ ! -f ${scriptsd}../.hap-wiz-env.sh ] && bash -c "python ${scriptsd}../library/hap-wiz-env.py $*"
source ${scriptsd}../.hap-wiz-env.sh
source ${scriptsd}dns-lookup.sh
yaml='02-hostap.yaml'
clientyaml='01-cliwpa.yaml'
nameservers_def="${PRIV_NETWORK}.1"
nameservers6_def="${PRIV_NETWORK_IPV6}1"
nameservers=''
nameservers6=''
NP_ORIG=/usr/share/netplan && sudo mkdir -p $NP_ORIG
NP_CLOUD=/etc/cloud/cloud.cfg.d && sudo mkdir -p $NP_CLOUD
slogger -st netplan "disable cloud-init"
sudo mv -fv /etc/netplan/50-cloud-init.yaml $NP_ORIG
echo -e "network: { config: disabled }" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
case "${WAN_INT}" in
  'eth'*)
    if [ -f /etc/init.d/networking ]; then
      echo -e "${MARKER_BEGIN}
auto lo
face lo inet loopback

allow-hotplug ${WAN_INT}
iface ${WAN_INT} inet dhcp
 network ${WAN_NETWORK}.0
${MARKER_END}" | sudo tee /etc/network/interfaces
    else
      echo -e "${MARKER_BEGIN}
network:
  version: 2
  renderer: networkd
  ethernets:
    ${WAN_INT}:
      dhcp4: yes
      dhcp6: yes
${MARKER_END}" | sudo tee /etc/netplan/$yaml
    fi
    ;;
  'wl'*);;
  *);;
esac
while [ "$#" -gt 0 ]; do case $1 in
  -r*|-R*)
    if [ -f /etc/init.d/networking ]; then
      sudo sed -i.old -e "${MARKERS}d" /etc/network/interfaces
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
    shift
    if [ -f /etc/init.d/networking ]; then
      source init_wpa_ctl.sh $*
    else
      slogger -st netplan "/etc/netplan/$clientyaml was created"
        echo -e "${MARKER_BEGIN}
network:
  version: 2
  renderer: networkd
  wifis:
    $1:
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
    echo -e $usage
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
bridge_ports ${PRIV_INT} ${WAN_INT}
${MARKER_END}" | sudo tee -a /etc/network/interfaces
     slogger -st brctl "share the internet wireless over bridge"
     sudo brctl addbr br0
     sudo brctl addif br0 eth0 ${PRIV_INT}
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
        - ${PRIV_INT}
        - ${WAN_INT}
${MARKER_END}" | sudo tee -a /etc/netplan/$yaml
   fi;;
   *);;
esac; shift; done
nameservers=$(nameservers $nameservers $nameservers_def)
nameservers6=$(nameservers $nameservers6 "'${nameservers6_def}'")
if [ -f /etc/init.d/networking ]; then
    slogger -st netman "add wifi network"
    export DEFAULT_GATEWAY=${PRIV_NETWORK}.1 \
    DEFAULT_MASKb=${PRIV_NETWORK_MASKb}
    case "${PRIV_WIFI_MODE}" in
      'a'*)
        export DEFAULT_WIFI_BAND="a";;
      'b'*|'g'*)
        export DEFAULT_WIFI_BAND="bg";;
    esac
    sudo python3 netman.py -t "hotspot" -i ${PRIV_INT} -s ${PRIV_SSID} --password="${PRIV_PAWD}"
    if [ $? -eq 0 ]; then
      slogger -st netman " Success"
    else
      slogger -st netman " Fail"
    fi
else
    slogger -st netplan "add wifi network"
    sudo sed -i.old /"password:"/a"\\
      addresses: [${PRIV_NETWORK}.1/${PRIV_NETWORK_MASKb}, '${PRIV_NETWORK_IPV6}1/${PRIV_NETWORK_MASKb6}']\\n\
      nameservers:\\n\
        addresses: [${nameservers},${nameservers6}]" /etc/netplan/$clientyaml
    sudo sed -i.old /"${PRIV_INT}:"/,/"${MARKER_END}"/s/yes/no/g /etc/netplan/$clientyaml
    cat /etc/netplan/$clientyaml | grep -A8 "${PRIV_INT}"
fi
