#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]
then
    echo -e "You need to run this script as root."
    exit 1
fi
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
banner=("" "[$0] BUILD RUNNING ${BASH_SOURCE[0]}" ""); printf "%s\n" "${banner[@]}"

if [ ! -f /etc/os-release ]
then
    echo -e "This script is made for Linux."
    [ "$(command -v sw_vers)" ] && sw_vers
    exit 1
fi
log_progress_msg "network configuration reset"
# shellcheck source=init.d/init_net_if.sh
"${scriptsd}/init.d/init_net_if.sh" -r
netplan apply --debug
"${scriptsd}/init.d/net_restart.sh"
