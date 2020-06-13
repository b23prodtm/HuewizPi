#!/usr/bin/env bash
usage="
Usage: $0 [-r]
  Configure the firewall rules
-r
  Removes all rules, disable firewall"
[ -z "${scriptsd}" ] && scriptsd=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
banner=("" "[$0] BUILD RUNNING ${BASH_SOURCE[0]}" ""); printf "%s\n" "${banner[@]}"
[ ! -f "${scriptsd}/../configure" ] && bash -c "python ${scriptsd}/../library/configure.py $*"
# shellcheck disable=SC1090
. "${scriptsd}/../configure"
cp -f "${scriptsd}"/../backup/etc/ufw/before.rules /etc/ufw/before.rules
while [ "$#" -gt 0 ]; do case $1 in
  -r*|-R*)
    sed -i -e "${MARKERS}d" /etc/ufw/before.rules
    ufw disable
    return;;
  -c*|--client)
    return;;
  -h*|--help)
    echo -e "$usage"
    exit 0;;
  *);;
esac; shift; done

slogger -st ipv4 "enable ip forwarding v4"
sed -i /net.ipv4.ip_forward/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
slogger -st ipv4 "enable ip forwarding v6"
sed -i /net.ipv6.conf.default.forwarding/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
sed -i /net.ipv6.conf.all.forwarding/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
slogger -st ufw "configure firewall"
sed -i /DEFAULT_FORWARD_POLICY/s/DROP/ACCEPT/g /etc/default/ufw
sleep 1
slogger -st ufw "add ip masquerading rules"
bash -c "sed -i -e ${MARKERS}d /etc/ufw/before.rules"
# shellcheck disable=SC2154
echo -e "${MARKER_BEGIN}
# nat Table rules
*nat
:POSTROUTING ACCEPT [0:0]

# Forward traffic from ${PRIV_INT} through eth0.
-A POSTROUTING -s ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb} -o ${WAN_INT} -j MASQUERADE
# ip6tables-restore:
#-A POSTROUTING -s ${PRIV_NETWORK_IPV6}0/${PRIV_NETWORK_MASKb6} -o ${WAN_INT} -j MASQUERADE

# dont delete the COMMIT line or these nat table rules wont be processed
COMMIT
${MARKER_END}" > /tmp/input.rules
cat /etc/ufw/before.rules >> /tmp/input.rules
sleep 1
slogger -st ufw "add packet ip forwarding"
echo -e "${MARKER_BEGIN}
-A ufw-before-forward -m state --state RELATED,ESTABLISHED -j ACCEPT
-A ufw-before-forward -i ${PRIV_INT} -s ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb} -o ${WAN_INT} -m state --state NEW -j ACCEPT
# ip6tables-restore:
#-A ufw-before-forward -i ${PRIV_INT} -s ${PRIV_NETWORK_IPV6}0/${PRIV_NETWORK_MASKb6} -o ${WAN_INT} -m state --state NEW -j ACCEPT
${MARKER_END}" > /tmp/input.rules.2
sed -e /"^# End required lines"/r/tmp/input.rules.2 /tmp/input.rules \
&& cp -f /tmp/input.rules /etc/ufw/before.rules
sleep 1
slogger -st ufw "allow ${PRIV_NETWORK}.0"
ufw allow from "${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb}"
ufw allow from "${PRIV_NETWORK_IPV6}0/${PRIV_NETWORK_MASKb6}"
slogger -st "ufw Balena makes use of the following ports:"
ufw allow https
ufw allow ntp
ufw allow 53
ufw --force enable
