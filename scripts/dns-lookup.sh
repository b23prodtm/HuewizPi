#!/usr/bin/env bash
[ -z ${scriptsd} ] && export scriptsd=$(cd `dirname $BASH_SOURCE` && pwd)
banner=("" "[$0] BUILD RUNNING $BASH_SOURCE" ""); printf "%s\n" "${banner[@]}"
function nameservers() {
  ns=$1
  sep=''
  while [ "$#" -gt 1 ]; do case $2 in
    "''"|'' );;
      *)
        [ $ns != '' ] && [ $ns != "''" ] && sep=','
        ns="${ns}${sep}$2";;
  esac; shift; done
  [[ $ns != '' ]] && [[ $ns != "''" ]] && echo $ns | sed -e s/,,//g -e s/,$// -e s/^,//
}
dns1=""
dns16=""
if [ -f /etc/os-release ]; then
#linux_family
  dns1=$(systemd-resolve --status | grep 'DNS Servers:' | awk '/([0-9]*\.){3}/{print $3}')
  dns16="$(systemd-resolve -6 --status | grep 'DNS Servers:' | awk '/(\w*:){2}/{print $3}' | head -n 1)"
  # | head -n 1)
else # mac_os
  dns1=$(scutil --dns | grep "nameserver\[.\] :" | awk '/([0-9]*\.){3}/{print $3}')
  # | head -n 1)
fi
printf "Here follow DNS addresses entries:\n"
nameservers $dns1
nameservers $dns16
printf "Let's run for it.\n"
