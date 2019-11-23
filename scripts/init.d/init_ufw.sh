#!/usr/bin/env bash
[ ! -f .hap-wiz-env.sh ] && python3 ${work_dir}../library/hap-wiz-env.py $*
source .hap-wiz-env.sh
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

logger -st ipv4 "enable ip forwarding v4"
sudo sed -i /net.ipv4.ip_forward/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
logger -st ipv4 "enable ip forwarding v6"
sudo sed -i /net.ipv6.conf.default.forwarding/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
sudo sed -i /net.ipv6.conf.all.forwarding/s/^\#// /etc/sysctl.conf /etc/ufw/sysctl.conf
logger -st ufw "configure firewall"
sudo sed -i /DEFAULT_FORWARD_POLICY/s/DROP/ACCEPT/g /etc/default/ufw
sleep 1
logger -st ufw "add ip masquerading rules"
bash -c "sudo sed -i -e ${MARKERS}d /etc/ufw/before.rules"
echo -e "${MARKER_BEGIN}\\n\
# nat Table rules\\n\
*nat\\n\
:POSTROUTING ACCEPT [0:0]\\n\
\\n\
# Forward traffic from wlan0 through eth0.\\n\
-A POSTROUTING -s ${NET}.0/${MASKb} -o ${INT} -j MASQUERADE\\n\
#-A POSTROUTING -s ${NET6}0/${MASKb6} -o ${INT} -j MASQUERADE\\n\
\\n\
# dont delete the COMMIT line or these nat table rules wont be processed\\n\
COMMIT\\n\
${MARKER_END}" | sudo tee /tmp/input.rules
sudo sed -i -e 1r/tmp/input.rules /etc/ufw/before.rules
sleep 1
logger -st ufw "add packet ip forwarding"
echo -e "${MARKER_BEGIN}\\n\
-A ufw-before-forward -m state --state RELATED,ESTABLISHED -j ACCEPT\\n\
-A ufw-before-forward -i wlan0 -s ${NET}.0/${MASKb} -o ${INT} -m state --state NEW -j ACCEPT\\n\
#-A ufw-before-forward -i wlan0 -s ${NET6}0/${MASKb6} -o ${INT} -m state --state NEW -j ACCEPT\\n\
${MARKER_END}" | sudo tee /tmp/input.rules
sudo sed -i -e /'^\# End required lines'/r/tmp/input.rules /etc/ufw/before.rules
sleep 1
logger -st ufw "allow ${NET}.0"
sudo ufw allow from ${NET}.0/${MASKb}
sudo ufw allow from ${NET6}0/${MASKb6}
sudo ufw --force enable
