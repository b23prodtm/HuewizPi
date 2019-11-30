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
printf "Here follows DNS address:\n  %s\nLet's run for it.\n" $dns1
