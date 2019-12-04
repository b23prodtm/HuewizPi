#!/bin/bash
# auto-reboot
# description: Check if the system dpkg need a restart and send corresponding signal
start() {
# code to start app comes here
# example: bahs -c "program_name" &
    bash -c "while [ ! -f /var/run/reboot-required ]; do sleep 30; done; cat /var/run/reboot-required.dpkgs 2> /dev/null; reboot" &
    echo $! > /var/run/chkdpkgs.pid
}
stop() {
# code to stop app comes here
# example: kill program_name.pid
kill $(cat /var/run/chkdpkgs.pid)
    rm /var/run/chkdpkgs.pid
}
status() {
if [ -e /var/run/chkdpkgs.pid ]; then
echo auto-reboot is running, pid=$(cat /var/run/chkdpkgs.pid)
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
*)
echo "Usage: $0 {start|stop|status|restart}"
esac
exit 0
