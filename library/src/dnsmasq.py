# start / stop the dnsmasq process

import subprocess
import time
import os
import ipaddress

DEFAULT_GATEWAY = "192.168.42.1"
DEFAULT_INTERFACE = "wlan0"
PROCESS = None


def get_dhcp_range(gateway, configured_range=None):
    router = ipaddress.ip_address(gateway)
    if router.version != 4:
        raise ValueError("The portal gateway must be an IPv4 address")
    network = ipaddress.ip_network("{}/24".format(router), strict=False)
    hosts = list(network.hosts())
    if router not in hosts:
        raise ValueError("The portal gateway must be a usable IPv4 address")
    if configured_range:
        start, end = [ipaddress.ip_address(value) for value in configured_range.split(",")]
        if start not in hosts or end not in hosts or start > end:
            raise ValueError("The DHCP range must be within the portal gateway subnet")
        if start <= router <= end:
            raise ValueError("The DHCP range must not include the portal gateway")
        return "{},{}".format(start, end)
    pool = [host for host in hosts if host != router]
    return "{},{}".format(pool[0], pool[-1])


def stop():
    global PROCESS
    if PROCESS is None:
        return
    if PROCESS.poll() is None:
        PROCESS.terminate()
        try:
            PROCESS.wait(timeout=3)
        except subprocess.TimeoutExpired:
            PROCESS.kill()
            PROCESS.wait()
    PROCESS = None


def start():
    global PROCESS
    # first kill any existing dnsmasq
    stop()

    gateway = os.getenv("DEFAULT_GATEWAY", DEFAULT_GATEWAY)
    dhcp_range = get_dhcp_range(gateway, os.getenv("DEFAULT_DHCP_RANGE"))
    interface = os.getenv("DEFAULT_INTERFACE", DEFAULT_INTERFACE)
    args = [
        "dnsmasq",
        "--listen-address={}".format(gateway),
        "--address=/#/{}".format(gateway),
        "--dhcp-range={}".format(dhcp_range),
        "--dhcp-option=option:router,{}".format(gateway),
        "--interface={}".format(interface),
        "--keep-in-foreground",
        "--bind-interfaces",
        "--except-interface=lo",
        "--dhcp-authoritative",
        "--no-hosts",
    ]
    PROCESS = subprocess.Popen(
        args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.2)
    if PROCESS.poll() is not None:
        status = PROCESS.returncode
        PROCESS = None
        raise RuntimeError("dnsmasq exited during startup (status {})".format(status))
    print("Started dnsmasq, PID={}".format(PROCESS.pid))
