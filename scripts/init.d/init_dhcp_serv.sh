#!/usr/bin/env bash
usage=("" \
"Usage: $0 [-r] [--router <ipv4>] [--dns <ipv4>] [--dns6 <ipv6>]" \
"       $0 [-l, --leases <hostname> [host_number]]" \
"              Initializes DHCP services (without dnsmasq)" \
"          -r" \
"              Disable all dhcp (also with dnsmasq) services" \
"          -l <hostname>" \
"              Prints ethernet mac address corresponding to the specified host DHCP lease. " \
"              A fixed address option will be added to /etc/dhcpd/dhcp.conf, " \
"              /etc/dhcpd/dhcp6.conf." \
"              Activate it by commenting out the host option." \
"          --router" \
"              Sets up router ip address for ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb}" \
"          --dns" \
"              Add a public custom DNS address (e.g. --dns 8.8.8.8 --dns 9.9.9.9)" \
"          --dns6" \
"              Add a public custom DNS ipv6 address(e.g. --dns6 2001:4860:4860::8888" \
"          --dns6 2001:4860:4860::8844)" \
"")
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
banner=("" "[$0] BUILD RUNNING ${BASH_SOURCE[0]}" ""); printf "%s\n" "${banner[@]}"
[ ! -f "${scriptsd}/../configure" ] && bash -c "python ${scriptsd}/../library/configure.py $*"
# shellcheck disable=SC1090
source "${scriptsd}/../configure"
# shellcheck source=../dns-lookup.sh
. "${scriptsd}/dns-lookup.sh" || true
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
RETURN=0
while [ "$#" -gt 0 ]; do case $1 in
  -r*|-R*)
    systemctl disable dnsmasq
    systemctl stop dnsmasq
    systemctl stop isc-dhcp-server
    systemctl stop isc-dhcp-server6
    systemctl disable isc-dhcp-server
    systemctl disable isc-dhcp-server6
    RETURN=1;;
  -h*|--help)
    echo -e "${usage[0]}"
    exit 0;;
  -l*|--leases*)
    lease_host=$2; lease_add=$3; lease=$(grep -C4 "$2" < /var/lib/dhcp/dhcpd.leases | grep -m1 "hardware ethernet" | awk -F' ' '{print $3}')
    [ -z "$3" ] && lease_add=${PRIV_RANGE_START}
    [ -n "${lease}" ] && lease_blk "${PRIV_NETWORK}.${lease_add}" > /tmp/input.dhcp.lease && sed -i \
-e \$s/\}// -e \$r/tmp/input.dhcp.lease -e \$a\} \
/etc/dhcp/dhcpd.conf && grep -B4 "fixed-address" < /etc/dhcp/dhcpd.conf
    systemctl restart isc-dhcp-server
    [ -n "${lease}" ] && lease_blk "${PRIV_NETWORK_IPV6}${lease_add}" > /tmp/input.dhcp.lease && sed -i \
-e \$s/\}// -e \$r/tmp/input.dhcp.lease -e \$a\} \
/etc/dhcp/dhcpd6.conf && grep -B4 "fixed-address" < /etc/dhcp/dhcpd6.conf
    systemctl restart isc-dhcp-server6
    RETURN=1;;
  --dns)
    nameservers=$(nameservers "$nameservers" "$2")
    shift;;
  --dns6)
    nameservers6=$(nameservers "$nameservers6" "$2")
    shift;;
  --router)
    routers="option routers $2;"
    shift;;
    *)
    echo -e "$0: Unknown option $1"
    exit 1;;
esac; shift; done
if [ "${RETURN}" = 0 ]; then
  echo -e "option domain-name-servers ${nameservers};

  default-lease-time 600;
  max-lease-time 7200;


  log-facility local7;

  subnet ${WAN_NETWORK}.0 netmask ${WAN_NETWORK_MASK} {}
  subnet ${PRIV_NETWORK}.0 netmask ${PRIV_NETWORK_MASK} {
  authoritative;
  # FQDN and subdomains from *.localhost
  option domain-name \"wifi.localhost\";
  ${routers}
  option subnet-mask ${PRIV_NETWORK_MASK};
  option broadcast-address ${PRIV_NETWORK}.255; # dhcpd
  range ${PRIV_NETWORK}.${PRIV_RANGE_START} ${PRIV_NETWORK}.${PRIV_RANGE_END};
  }" > /etc/dhcp/dhcpd.conf
  # shellcheck disable=SC2154
  echo -e "option dhcp6.name-servers ${nameservers6};

  default-lease-time 600;
  max-lease-time 7200;
  log-facility local7;
  subnet6 ${WAN_NETWORK_IPV6}0/${WAN_NETWORK_MASKb6} {}
  subnet6 ${PRIV_NETWORK_IPV6}0/${PRIV_NETWORK_MASKb6} {
  authoritative;
  option dhcp6.domain-name \"wifi.localhost\";
  range6 ${PRIV_NETWORK_IPV6}${PRIV_RANGE_START} ${PRIV_NETWORK_IPV6}${PRIV_RANGE_END};
  }" > /etc/dhcp/dhcpd6.conf
  sed -i -e "s/INTERFACESv4=\".*\"/INTERFACESv4=\"${PRIV_INT}\"/" /etc/default/isc-dhcp-server
  sed -i -e "s/INTERFACESv6=\".*\"/INTERFACESv6=\"${PRIV_INT}\"/" /etc/default/isc-dhcp-server
  #delete empty strings '', and ''
  sed -i -e s/\'\',//g -e s/\'\'//g /etc/dhcp/dhcpd6.conf
  cat /etc/default/isc-dhcp-server
  sleep 1
  slogger -st dhcpd "start DHCP server"
  systemctl unmask isc-dhcp-server
  systemctl enable isc-dhcp-server
  systemctl start isc-dhcp-server
  systemctl unmask isc-dhcp-server6
  systemctl enable isc-dhcp-server6
  systemctl start isc-dhcp-server6
fi
