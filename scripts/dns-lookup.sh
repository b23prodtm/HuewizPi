#!/usr/bin/env bash
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
banner=("" "[$0] BUILD RUNNING ${BASH_SOURCE[0]}" ""); printf "%s\n" "${banner[@]}"
# shellcheck source=../library/init-functions.sh
source "${scriptsd}/../library/init-functions.sh"
function nameservers() {
  ns=$1
  shift
  sep=''
  while [ "$#" -gt 0 ]; do case $1 in
    "''"|'' );;
      *)
        [ "$ns" != '' ] && [ "$ns" != "''" ] && sep=','
        ns="${ns}${sep}$1";;
  esac; shift; done
  if [[ $ns != '' ]] && [[ $ns != "''" ]]; then
    echo "$ns" | sed -e "s/,[ ]*,/,/g" -e "s/,$//g "-e "s/^,//g"
  fi
}
dns1=""
dns16=""
function linux_dns_ipv4() {
  if ! systemd-resolve --status | grep 'DNS Servers:' | awk '/([0-9]*\.){3}/{print $3}'; then
    log_failure_msg "Host down or doesn't handle sd_bus_open_system.\n"
  fi
}

function linux_dns_ipv6() {
  if ! systemd-resolve -6 --status | grep 'DNS Servers:' | awk '/(\w*:){2}/{print $3}' | head -n 1; then
    log_failure_msg "Host (ipv6) down or doesn't handle sd_bus_open_system.\n"
  fi
}
if [ -f /etc/os-release ]; then
  # linux_family (TODO: not alpine)
  read -r -a dns1 <<< "$(linux_dns_ipv4)"
  read -r -a dns16 <<< "$(linux_dns_ipv6)"
else # mac_os
  read -r -a dns1 <<< "$(scutil --dns | grep "nameserver\[.\] :" | awk '/([0-9]*\.){3}/{print $3}')"
fi
log_daemon_msg "Here follow DNS addresses entries:\n"
nameservers "${dns1[@]}"
nameservers "${dns16[@]}"
