# start / stop the dnsmasq process

import subprocess, time, os

DEFAULT_GATEWAY=os.getenv("DEFAULT_GATEWAY", "192.168.42.1")
DEFAULT_DHCP_RANGE=os.getenv("DEFAULT_DHCP_RANGE","192.168.42.2,192.168.42.254")
DEFAULT_INTERFACE=os.getenv('DEFAULT_INTERFACE',"wlan0") # use 'ip link show' to see list of interfaces

def stop():
    pid = subprocess.getoutput("ps -e | grep ' dnsmasq' | cut -c 1-6").strip()
    if pid:
        print(f"Killing dnsmasq, PID='{pid}'")
        subprocess.run(f"kill -9 {pid}", shell=True, check=False)



def start():
    # first kill any existing dnsmasq
    stop()

    # build the list of args
    args = ["dnsmasq"]
    args.append(f"--listen-address={DEFAULT_GATEWAY}")
    args.append(f"--address=/#/{DEFAULT_GATEWAY}")
    args.append(f"--dhcp-range={DEFAULT_DHCP_RANGE}")
    args.append(f"--dhcp-option=option:router,{DEFAULT_GATEWAY}")
    args.append(f"--interface={DEFAULT_INTERFACE}")
    args.append("--keep-in-foreground")
    args.append("--bind-interfaces")
    args.append("--except-interface=lo")
    args.append("--dhcp-authoritative")
    args.append("--no-hosts" )

    # run dnsmasq in the background and save a reference to the object
    ps = subprocess.Popen(args)
    # don't wait here, proc runs in background until we kill it.

    # give a few seconds for the proc to start
    time.sleep(2)
    print('Started dnsmasq, PID={}'.format(ps.pid))
