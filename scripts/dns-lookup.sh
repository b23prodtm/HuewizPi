#!/usr/bin/env bash
dns1=""
if [ -f /etc/os-release ]; then
#linux_family
  dns1=$(systemd-resolve --status | grep 'DNS Servers:' | awk '/([0-9]*\.){3}/{print $3}')
  # | head -n 1)
else # mac_os
  dns1=$(scutil --dns | grep "nameserver\[.\] :" | awk '/([0-9]*\.){3}/{print $3}')
  # | head -n 1)
fi
s="ip: %s\n"
while [ "$#" -gt 0 ]; do case $1 in
  -s*)
    s="%s\n";;
  * );;
esac; shift; done
printf "Here follow DNS addresses entries:\n"
printf "$s" $dns1
printf "Let's run for it.\n"
