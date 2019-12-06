#!/bin/bash
# auto-reboot
# description: Check if the system dpkg need a restart and send corresponding signal
[ -z ${scriptsd} ] && export scriptsd=../$(echo $0 | awk 'BEGIN{FS="/";ORS="/"}{ for(i=1;i<NF;i++) print $i }')
install() {
  sudo cp -f ${scriptsd}init.d/auto-reboot.sh /usr/local/bin/auto-reboot.sh
  sudo chmod +x /usr/local/bin/auto-reboot.sh
  sudo cp -f ${scriptsd}init.d/auto-reboot.service /etc/systemd/system/auto-reboot.service
  sudo systemctl enable auto-reboot
}
uninstall() {
  sudo systemctl disable auto-reboot
  sudo rm -f /usr/local/bin/auto-reboot.sh
  sudo rm -f /etc/systemd/system/auto-reboot.service
}
start() {
# code to start app comes here
# example: bahs -c "program_name" &
    bash -c "while [ ! -f /run/reboot-required ]; do sleep 30; done; cat /run/reboot-required.dpkgs 2> /dev/null; reboot" &
    echo $! > /run/chkdpkgs.pid
}
stop() {
# code to stop app comes here
# example: kill program_name.pid
  kill $(cat /run/chkdpkgs.pid)
  rm /run/chkdpkgs.pid
}
status() {
if [ -e /run/chkdpkgs.pid ]; then
  echo auto-reboot is running, pid=$(cat /run/chkdpkgs.pid)
else
  echo auto-reboot is NOT running
  exit 1
fi
}
case "$1" in
    start)
       start
       ;;
    stop)
       stop
       ;;
    restart)
       stop
       start
       ;;
    status)
# code to check status of app comes here
# example: status program_name
       status
       ;;
    install)
       install
       ;;
    uninstall)
       uninstall
       ;;
*)
echo "Usage: $0 {start|stop|status|restart|install|uninstall}"
esac
exit 0
