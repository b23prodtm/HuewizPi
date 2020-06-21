#!/usr/bin/python3
import sys
import os
import re
import ipaddress as ip
import locale as lc
if int(sys.version.partition('.')[0]) < 3:
    print("This script needs python 3 or later. Try python3.")
    exit(1)
defnet = ip.ip_network('192.168.2.0/24')
defnet6 = ip.ip_network('2a01:db8:0:1::0/64')
defintnet = ip.ip_network('192.168.0.0/24')
defintnet6 = ip.ip_network('2a01:e0a:16b:dc30::0/64')
defdns1 = ip.ip_address('8.8.8.8')
defdns2 = ip.ip_address('8.8.4.4')
defdns61 = ip.ip_address('2001:4860:4860::8888')
defdns62 = ip.ip_address('2001:4860:4860::8844')
myenv = dict()
myenv.update(os.environ)


def parse_args(argv):
    mb = "# BEGIN GENERATED hostapd"
    me = "# END GENERATED hostapd"
    markers = {
        "MARKER_BEGIN": mb,
        "MARKER_END": me,
        "MARKERS": "/'" + mb + "'/,/'" + me + "'/"
    }
    myenv.update(markers)
    defaults = {
        "file": argv[0],
        "PRIV_INT": "wlan0",
        "PRIV_NETWORK": "",
        "WAN_NETWORK": defintnet.with_prefixlen,
        "WAN_INT": "eth0",
        "PRIV_SSID": "",
        "PRIV_PASSWD": "",
        "PRIV_WIFI_MODE": "",
        "PRIV_WIFI_CTY": "",
        "PRIV_WIFI_CHANNEL": "",
        "DNS1": "",
        "DNS2": str(defdns2),
        "WAN_SSID": "",
        "WAN_PASSWD": "",
        "PRIV_RANGE_START": "15",
        "PRIV_RANGE_END": "100",
        "PRIV_NETWORK_IPV6": defnet6.with_prefixlen,
        "WAN_NETWORK_IPV6": defintnet6.with_prefixlen,
        "DNS1_IPV6": str(defdns61),
        "DNS2_IPV6": str(defdns62)
        }
    usage = ('Usage: {}'.format(argv[0]),
             'optional:	[-c,--client]'
             'required:	<priv_interface> <priv-network-x.x.x.0/len>',
             'required:	<wan-network-x.x.x.0/len> <wan-interface>',
             'user input:	[ssid passphrase [mode] [country_code channel]',
             'user input:	[dns1 dns2]',
             'w/ wan wlan1:	[wan_ssid wan_passphrase]',
             'optional:	[net-range-start net-range-end]',
             'optional:	[priv-net-ipv6/mask-length wan-net-ipv6/mask-length]',
             'optional:	[dns1-ipv6 dns2-ipv6]')
    r_parse_argv(defaults, argv, 1, 'hc', '\n		'.join(usage))


def r_parse_argv(defaults, argv, i, options, usage):
    """Parse script arguments recursively
    i -- index in both argv and defaults
    options -- Literals set of options, e.g. afh, -a, -f, -h, -afh
    """
    if i >= len(defaults):
        return
    if len(argv) < 5:
        print(usage)
        sys.exit(1)
    pf = "-+[" + options + "]*"
    client = re.compile(pf + "c(lient)?.*")
    help = re.compile(pf + "h(elp)?.*")
    any = re.compile(pf)
    if i < len(argv):
        if client.match(argv[i]):
            myenv['CLIENT'] = argv[i]
            del argv[i]
        elif help.match(argv[i]):
            print(usage)
            sys.exit(0)
        elif any.match(argv[i]):
            del argv[i]
    n = 0
    for k in defaults.keys():
        if n == i:
            var = [k, argv[i] if len(argv) > i else defaults[k]]
            var = format_argv(var)
            myenv[var[0]] = var[1]
            break
        else:
            n = n + 1
    return r_parse_argv(defaults, argv, i+1, options, usage)


def format_argv(var):
    if var[0] == "PRIV_NETWORK" or var[0] == "WAN_NETWORK":
        net = ip.ip_network(var[1]) if var[1] != "" else defnet
        # trim last .0
        m = re.match(r'(\d*\.){2}(\d*)', str(net.network_address))
        if m:
            var[1] = m.group()
        if var[0] == "PRIV_NETWORK":
            myenv["PRIV_NETWORK_MASK"] = str(net.netmask)
            myenv["PRIV_NETWORK_MASKb"] = "%s" % net.prefixlen
        if var[0] == "WAN_NETWORK":
            myenv["WAN_NETWORK_MASK"] = str(net.netmask)
            myenv["WAN_NETWORK_MASKb"] = "%s" % net.prefixlen
    if var[0] == "PRIV_NETWORK_IPV6" or var[0] == "WAN_NETWORK_IPV6":
        net6 = ip.ip_network(var[1]) if var[1] != "" else defnet6
        # trim last :0
        m = re.match(r'(\w*:){1,7}', str(net6.network_address))
        if m:
            var[1] = m.group()
        if var[0] == "PRIV_NETWORK_IPV6":
            myenv["PRIV_NETWORK_MASK6"] = str(net6.netmask)
            myenv["PRIV_NETWORK_MASKb6"] = "%s" % net6.prefixlen
        if var[0] == "WAN_NETWORK_IPV6":
            myenv["WAN_NETWORK_MASK6"] = str(net6.netmask)
            myenv["WAN_NETWORK_MASKb6"] = "%s" % net6.prefixlen
    return var


def main(argv):
    parse_args(argv)
    while myenv["PRIV_SSID"] == "":
        myenv["PRIV_SSID"] = input("Please set a name for the Wifi Network: ")
    while len(myenv["PRIV_PASSWD"]) < 8 or len(myenv["PRIV_PASSWD"]) > 63:
        text = "%s password (8..63 chars): " % myenv["PRIV_SSID"]
        myenv["PRIV_PASSWD"] = input(text)
    while myenv["PRIV_WIFI_MODE"] not in ['a', 'b', 'g']:
        text = "(a = IEEE 802.11ac, g = IEEE 802.11n; b = IEEE 802.11b) [a]"
        myenv["PRIV_WIFI_MODE"] = input("WIFI mode %s: " % text)
        if myenv["PRIV_WIFI_MODE"] == "":
            myenv["PRIV_WIFI_MODE"] = 'a'
    while myenv["PRIV_WIFI_CTY"] == "":
        cty_code = re.match(".*_([A-Z]*)", lc.getlocale()[0]).group(1)
        if not cty_code:
            cty_code = re.match("[A-Z]*", lc.getlocale()).group()
        text = "Country code to use [%s]: " % cty_code
        myenv["PRIV_WIFI_CTY"] = input(text)
        if myenv["PRIV_WIFI_CTY"] == "":
            myenv["PRIV_WIFI_CTY"] = cty_code
    while myenv["PRIV_WIFI_CHANNEL"] == "":
        text = ['0 = ACS tuning',
                '36,40,..,140 = 5GHz (US,EU)',
                '149,153,161,165 = 5Ghz (US,CN)',
                '1-14 = 2,4Ghz']
        s = ', '
        myenv["PRIV_WIFI_CHANNEL"] = input('Channel (%s) [0]:' % s.join(text))
        if myenv["PRIV_WIFI_CHANNEL"] == "":
            myenv["PRIV_WIFI_CHANNEL"] = "0"
    while myenv["DNS1"] == "":
        dns1 = input("DNS server [ENTER = %s]: " % str(defdns1))
        try:
            if dns1 == "":
                myenv["DNS1"] = str(defdns1)
            else:
                myenv["DNS1"] = str(ip.ip_address(dns1))
        except ValueError as err:
            print("Oops! Please set a valid IPv4 address".format(err))
            sys.exit(1)
    wl = re.compile("wl.*");
    if wl.match(myenv["WAN_INT"]):
        while myenv["WAN_SSID"] == "":
            myenv["WAN_SSID"] = input("%s SSID: " % myenv["WAN_INT"])
        while len(myenv["WAN_PASSWD"]) < 8 or len(myenv["WAN_PASSWD"]) > 63:
            text = "%s password (8..63 chars): " % myenv["WAN_SSID"]
            myenv["WAN_PASSWD"] = input(text)
    os.environ.update(myenv)
    write_exports(myenv)


def write_exports(envdict):
    print("Current working dir : %s" % os.getcwd())
    path = "configure"
    f = open(path, "w")
    f.write("#!/usr/bin/env bash\nexport ")
    for k, v in myenv.items():
        var = '='.join([k, '"%s"' % v])
        f.write(' \\\n%s' % var)
    f.write("\n. init_functions \"${BASH_SOURCE[0]}\" \"$@\"\n")
    f.write("\nfunction slogger() {\n")
    f.write("  [ -f /dev/log ] && logger \"$@\" && return\n")
    f.write("  [ \"$#\" -gt 1 ] && shift\n")
    f.write("  log_daemon_msg \"$@\"\n")
    f.write("}\n")
    f.close()
    os.chmod(path, 0o755)


if __name__ == '__main__':
    banner = ('', 'BUILD RUNNING python3', sys.argv[0], '')
    print("{}\n{}\n{}\n{}\n".format(*banner))
    main(sys.argv)
