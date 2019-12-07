#!/usr/bin/env bash
[ -z ${scriptsd} ] && export scriptsd=../$(echo $0 | awk 'BEGIN{FS="/";ORS="/"}{ for(i=1;i<NF;i++) print $i }')
[ ! -f ${scriptsd}../.hap-wiz-env.sh ] && bash -c "python ${scriptsd}../library/hap-wiz-env.py $*"
source ${scriptsd}../.hap-wiz-env.sh
while [ "$#" -gt 0 ]; do case $1 in
  -r*|-R*)
    bash -c "sudo sed -i -e ${MARKERS}d /etc/ufw/before.rules"
    sudo ufw disable
    return;;
  -c*|--client)
    return;;
  -h*|--help)
    echo "Usage: $0 [-r]
  Configure the firewall rules
  -r
    Removes all rules, disable firewall"
    exit 1;;
  *);;
esac; shift; done

slogger -st ipv4 "enable ip forwarding v4"
sudo sed -i /net.ipv4.ip_forward/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
slogger -st ipv4 "enable ip forwarding v6"
sudo sed -i /net.ipv6.conf.default.forwarding/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
sudo sed -i /net.ipv6.conf.all.forwarding/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
slogger -st ufw "configure firewall"
sudo sed -i /DEFAULT_FORWARD_POLICY/s/DROP/ACCEPT/g /etc/default/ufw
sleep 1
slogger -st ufw "add ip masquerading rules"
bash -c "sudo sed -i -e ${MARKERS}d /etc/ufw/before.rules"
echo -e "${MARKER_BEGIN}\\n\
# nat Table rules\\n\
*nat\\n\
:POSTROUTING ACCEPT [0:0]\\n\
\\n\
# Forward traffic from wlan0 through eth0.\\n\
-A POSTROUTING -s ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb} -o ${WAN_INT} -j MASQUERADE\\n\
#-A POSTROUTING -s ${PRIV_NETWORK_IPV6}0/${PRIV_NETWORK_MASKb6} -o ${WAN_INT} -j MASQUERADE\\n\
\\n\
# dont delete the COMMIT line or these nat table rules wont be processed\\n\
COMMIT\\n\
${MARKER_END}" | sudo tee /tmp/input.rules
sudo sed -i -e 1r/tmp/input.rules /etc/ufw/before.rules
sleep 1
slogger -st ufw "add packet ip forwarding"
echo -e "${MARKER_BEGIN}\\n\
-A ufw-before-forward -m state --state RELATED,ESTABLISHED -j ACCEPT\\n\
-A ufw-before-forward -i wlan0 -s ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb} -o ${WAN_INT} -m state --state NEW -j ACCEPT\\n\
#-A ufw-before-forward -i wlan0 -s ${PRIV_NETWORK_IPV6}0/${PRIV_NETWORK_MASKb6} -o ${WAN_INT} -m state --state NEW -j ACCEPT\\n\
${MARKER_END}" | sudo tee /tmp/input.rules
sudo sed -i -e /'^\# End required lines'/r/tmp/input.rules /etc/ufw/before.rules
sleep 1
slogger -st ufw "allow ${PRIV_NETWORK}.0"
sudo ufw allow from ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb}
sudo ufw allow from ${PRIV_NETWORK_IPV6}0/${PRIV_NETWORK_MASKb6}
sudo ufw --force enable
