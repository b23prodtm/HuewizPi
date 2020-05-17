#!/usr/bin/env bash
usage="
Usage: $0 [interface] <ssid> <passphrase>"
[ -z ${scriptsd} ] && export scriptsd=$(cd `dirname $BASH_SOURCE`/.. && pwd)
banner=("" "[$0] BUILD RUNNING $BASH_SOURCE" ""); printf "%s\n" "${banner[@]}"
[ ! -f ${scriptsd}/../.hap-wiz-env.sh ] && bash -c "python ${scriptsd}/../library/hap-wiz-env.py $*"
source ${scriptsd}/../.hap-wiz-env.sh
function cfrm_act () {
  def_go=$2
  y='y'
  n='n'
  [ "$def_go" == "$y" ] && y='Y'
  [ "$def_go" == "$n" ] && n='N'
  while true; do case $go in
          [nN]*) break;;
          [yY]*) echo $go; break;;
  	*)
  		read -p "
  Confirm $1 [${y}/${n}] ? " go
  		[ -z $go ] && go=$def_go;;
  esac; done
  #Usage: $0 <description> yY|nN
}
function prompt_arrgs () {
  IFS=' ' # Read prompt Field Separator
  if [[ "$#" -gt 3 ]]; then
    shift; shift; shift; ARRGS=$@;
  else
    size=$1
    desc=$2
    desc_precise=$3
    while [[ -z $ARRGS ]]; do
    	read -p "
  Please type in $desc...: (CTRL-C to exit) " -a arrgs
    	if [[ ${#arrgs[@]} -ge $size ]]; then
      	if [[ $(cfrm_act "you've entered $desc ${arrgs[0]} ${arrgs[1]} ${arrgs[2]}.." 'n') > /dev/null ]]; then
      		ARRGS=${arrgs[@]}
      	fi
      else
          echo -e "
  Enter $size values : $desc $desc_precise"
      fi
    done
  fi
  echo $ARRGS
  #Usage: $0 <array_size> <description> <example_values> [array values]
}
ssid=''
password=''
INTERFACE='wlan0'
while [ "$#" -gt 0 ]; do case $1 in
  wl*)
    INTERFACE=$1;;
  *)
    ssid="$1"
    password="$2"
    shift;;
esac; shift; done
slogger -st init_wpa_ctl "Add Wifi password access"
[ -z $ssid ] && ssid=$(prompt_arrgs 1 'a Wifi SSID' 'e.g. MyWifiNetwork')
[ -z $ssid ] && exit 1
[ -z $password ] && ssid=$(prompt_arrgs 1 'a Wifi passphrase' 'e.g. myWip+Swod')
[ -z $password ] && exit 1
slogger -st netman "set Wifi SSID connection"
sudo python3 netman.py -t "PASSWORD" -i $INTERFACE --ssid="${ssid}" --password="${password}"
if [ $? -eq 0 ]; then
  slogger -st netman " Success"
else
  slogger -st netman " Fail"
  exit 1
fi
