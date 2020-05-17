#!/usr/bin/env bash
usage="
Usage: $0 [-r] [--router <ipv4>] [--dns <ipv4>] [--dns6 <ipv6>]
   $0 [-l, --leases <hostname> [host_number]]
Initializes DHCP services (without dnsmasq)
-r
Disable all dhcp (also with dnsmasq) services
-l <hostname>
Prints ethernet mac address corresponding to the specified host DHCP lease. \
A fixed address option will be added to /etc/dhcpd/dhcp.conf, /etc/dhcpd/dhcp6.conf.
Activate it by commenting out the host option.
--router
Sets up router ip address for ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb}
--dns
Add a public custom DNS address (e.g. --dns 8.8.8.8 --dns 9.9.9.9)
--dns6
Add a public custom DNS ipv6 address(e.g. --dns6 2001:4860:4860::8888 --dns6 2001:4860:4860::8844)
"
[ -z ${scriptsd} ] && export scriptsd=$(cd `dirname $BASH_SOURCE`/.. && pwd)
banner=("" "[$0] BUILD RUNNING $BASH_SOURCE" ""); printf "%s\n" "${banner[@]}"
[ ! -f ${scriptsd}/../.hap-wiz-env.sh ] && bash -c "python ${scriptsd}/../library/hap-wiz-env.py $*"
source ${scriptsd}/../.hap-wiz-env.sh
source ${scriptsd}/dns-lookup.sh
routers="option routers ${PRIV_NETWORK}.1; #hostapd ${PRIV_INT}"
nameservers=$(systemd-resolve --status | grep 'DNS Servers:' | awk '/(\w*\.){3}/{print $3}' | head -n 1)
nameservers6="$(systemd-resolve -6 --status | grep 'DNS Servers:' | awk '/(\w*:){2}/{print $3}' | head -n 1)"
function lease_blk() {
  address=$1
echo -e "${MARKER_BEGIN} \n\
# Example for a fixed host address try $0 --leases <hostname> [host_number]  \n\
      host ${lease_host} { # host hostname (dhcp-leases-list) \n\
      hardware ethernet ${lease} # hardware ethernet 00:00:00:00:00:00 (/var/lib/dhcp/dhcpd.leases); \n\
        fixed-address ${address}; } \n\
${MARKER_END}"
}
while [ "$#" -gt 0 ]; do case $1 in
  -r*|-R*)
    sudo systemctl disable dnsmasq
    sudo systemctl stop dnsmasq
    sudo systemctl stop isc-dhcp-server
    sudo systemctl stop isc-dhcp-server6
    sudo systemctl disable isc-dhcp-server
    sudo systemctl disable isc-dhcp-server6
    return;;
  -h*|--help)
    echo -e $usage
    exit 1;;
  -l*|--leases*)
    lease_host=$2; lease_add=$3; lease=$(cat /var/lib/dhcp/dhcpd.leases | grep -C4 $2 | grep -m1 "hardware ethernet" | awk -F' ' '{print $3}')
    [ -z $3 ] && lease_add=${PRIV_RANGE_START}
   [ ! -z ${lease} ] && lease_blk ${PRIV_NETWORK}.${lease_add} | sudo tee /tmp/input.dhcp.lease && sudo sed -i \
-e \$s/\}// -e \$r/tmp/input.dhcp.lease -e \$a\} \
/etc/dhcp/dhcpd.conf && cat /etc/dhcp/dhcpd.conf | grep -B4 "fixed-address"
   sudo systemctl restart isc-dhcp-server
   [ ! -z ${lease} ] && lease_blk ${PRIV_NETWORK_IPV6}${lease_add} | sudo tee /tmp/input.dhcp.lease && sudo sed -i \
-e \$s/\}// -e \$r/tmp/input.dhcp.lease -e \$a\} \
/etc/dhcp/dhcpd6.conf && cat /etc/dhcp/dhcpd6.conf | grep -B4 "fixed-address"
    sudo systemctl restart isc-dhcp-server6
    exit 0;;
  --dns)
    nameservers=$(nameservers $nameservers $2)
    shift;;
  --dns6)
    nameservers6=$(nameservers $nameservers6 $2)
    shift;;
  --router)
    routers="option routers $2;"
    shift;;
    *)
    echo -e "$0: Unknown option $1";;
esac; shift; done
echo -e "option domain-name-servers ${nameservers};

default-lease-time 600;
max-lease-time 7200;

authoritative;

log-facility local7;

#subnet ${WAN_NETWORK}.0 netmask ${WAN_NETWORK_MASK} {}
subnet ${PRIV_NETWORK}.0 netmask ${PRIV_NETWORK_MASK} {
#option domain-name "wifi.localhost";
${routers}
option subnet-mask ${PRIV_NETWORK_MASK};
option broadcast-address ${PRIV_NETWORK}.0; # dhcpd
range ${PRIV_NETWORK}.${PRIV_RANGE_START} ${PRIV_NETWORK}.${PRIV_RANGE_END};
}" | sudo tee /etc/dhcp/dhcpd.conf
echo -e "option dhcp6.name-servers ${nameservers6};

default-lease-time 600;
max-lease-time 7200;

authoritative;

log-facility local7;

#subnet6 ${WAN_NETWORK_IPV6}0/${WAN_NETWORK_MASKb6} {}
subnet6 ${PRIV_NETWORK_IPV6}0/${PRIV_NETWORK_MASKb6} {
#option dhcp6.domain-name "wifi.localhost";
range6 ${PRIV_NETWORK_IPV6}${PRIV_RANGE_START} ${PRIV_NETWORK_IPV6}${PRIV_RANGE_END};
}" | sudo tee /etc/dhcp/dhcpd6.conf
sudo sed -i -e "s/INTERFACESv4=\".*\"/INTERFACESv4=\"${PRIV_INT}\"/" /etc/default/isc-dhcp-server
sudo sed -i -e "s/INTERFACESv6=\".*\"/INTERFACESv6=\"${PRIV_INT}\"/" /etc/default/isc-dhcp-server
#delete empty strings '', and ''
sudo sed -i -e s/\'\',//g -e s/\'\'//g /etc/dhcp/dhcpd6.conf
sudo cat /etc/default/isc-dhcp-server
sleep 1
slogger -st dhcpd "start DHCP server"
sudo systemctl unmask isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl start isc-dhcp-server
sudo systemctl unmask isc-dhcp-server6
sudo systemctl enable isc-dhcp-server6
sudo systemctl start isc-dhcp-server6
