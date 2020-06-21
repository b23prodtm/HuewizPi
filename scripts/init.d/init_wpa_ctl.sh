#!/usr/bin/env bash
usage=("" \
"Usage: $0 [interface] <ssid> <passphrase>" \
"" \
"Obsolete script, use instead ./init_net_if.sh --wifi [wl*] <ssid> <passphrase>" \
"")
[ "$#" -lt 2 ] && printf "%s\n" "${usage[0]}"
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
banner=("" "[$0] BUILD RUNNING ${BASH_SOURCE[0]}" ""); printf "%s\n" "${banner[@]}"
[ ! -f "${scriptsd}/../configure" ] && bash -c "python ${scriptsd}/../library/configure.py $*"
# shellcheck disable=SC1090
. "${scriptsd}/../configure"
function cfrm_act () {
  def_go=$2
  y='y'
  n='n'
  [ "$def_go" == "$y" ] && y='Y'
  [ "$def_go" == "$n" ] && n='N'
  while true; do case $go in
          [nN]*) break;;
          [yY]*) echo "$go"; break;;
  	*)
  		read -rp "
  Confirm $1 [${y}/${n}] ? " go
  		[ -z "$go" ] && go=$def_go;;
  esac; done
  #Usage: $0 <description> yY|nN
}
function prompt_arrgs () {
  IFS=' ' # Read prompt Field Separator
  if [[ "$#" -gt 3 ]]; then
    shift 3; ARRGS="$*";
  else
    size=$1
    desc=$2
    desc_precise=$3
    while [[ -z $ARRGS ]]; do
      read -rp "
  Please type in $desc...: (CTRL-C to exit) " -a arrgs
      if [[ ${#arrgs[@]} -ge $size ]]; then
        if [[ $(cfrm_act "you've entered $desc ${arrgs[0]} ${arrgs[1]} ${arrgs[2]}.." 'n') ]]; then
          ARRGS="${arrgs[*]}"
        fi
      else
          echo -e "
  Enter $size values : $desc $desc_precise"
      fi
    done
  fi
  echo "$ARRGS"
  #Usage: $0 <array_size> <description> <example_values> [array values]
}
ssid=''
password=''
INTERFACE='wlan0'
while [ "$#" -gt 0 ]; do case $1 in
  wl*)
    INTERFACE="$1";;
  *)
    ssid="$1"
    password="$2"
    shift;;
esac; shift; done
slogger -st init_wpa_ctl "Add Wifi password access"
[ -z "$ssid" ] && ssid=$(prompt_arrgs 1 'a Wifi SSID' 'e.g. MyWifiNetwork')
[ -z "$ssid" ] && exit 1
[ -z "$password" ] && password=$(prompt_arrgs 1 'a Wifi passphrase' 'e.g. myWip+Swod')
[ -z "$password" ] && exit 1
slogger -st netman "set Wifi SSID connection"
if python3 "${scriptsd}/../library/src/netman.py" -t "PASSWORD" -i "$INTERFACE" --ssid="${ssid}" --password="${password}"; then
  log_success_msg "netman set wifi connection"
else
  log_success_msg "netman failed set wifi connection"
fi
