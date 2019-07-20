#!/usr/bin/python
import sys
if int(sys.version.partition('.')[0]) < 3:
    print("This script needs python 3 or later. Try python3.")
    exit(1)
import os
import re
import ipaddress as ip
import locale as lc
defnet = ip.ip_network('192.168.2.0/24')
defnet6 = ip.ip_network('2a01:db8:0:1::0/64')
defintnet = ip.ip_network('192.168.0.0/24')
defintnet6 = ip.ip_network('2a01:e0a:16b:dc30::0/64')
myenv = dict()
def parse_args (argv):
    mb = "# BEGIN GENERATED hostapd"
    me = "# END GENERATED hostapd"
    markers = {
        "MARKER_BEGIN":mb,
        "MARKER_END":me,
        "MARKERS":"/'" + mb + "'/,/'" + me + "'/"
    }
    myenv.update(markers)
    defaults = {
        "file":argv[0],
        "NET":"",
        "INTNET":defintnet.with_prefixlen,
        "INT":"eth0",
        "SSID":"",
        "PAWD":"",
        "MODE":"",
        "CTY_CODE":"",
        "CHANNEL":"",
        "NET_start":"15",
        "NET_end":"100",
        "NET6":defnet6.with_prefixlen,
        "INTNET6":defintnet6.with_prefixlen
     }
    r_parse_argv(defaults, argv, 1, 'hc', "Usage: {} [-c,--client] <priv-network-x.x.x.0/len> <wan-network-x.x.x.0/len> <wan-interface> [ssid passphrase [mode] [country_code channel] [net-range-start net-range-end] [priv-network-ipv6/mask-length wan-network-ipv6/mask-length]]".format(argv[0]))

def r_parse_argv(defaults, argv, i, options, usage):
    """Parse script arguments recursively
    i -- index in both argv and defaults
    options -- Literals set of options, e.g. afh where -a, -f, -h are valid options as for -afh
    """
    if i >= len(defaults) : return
    pf = "-+[" + options + "]*"
    client = re.compile(pf + "c(lient)?.*")
    help = re.compile(pf + "h(elp)?.*")
    any = re.compile(pf)
    if i < len(argv):
        if client.match(argv[i]):
            myenv['CLIENT'] = argv[i]
            del argv[i]
        elif help.match(argv[1]):
            print(usage)
            sys.exit(0)
        elif any.match(argv[i]):
            del argv[i]
    n = 0
    for k in defaults.keys():
         if n == i:
             var = [ k, argv[i] if len(argv) > i else defaults[k] ]
             var = format_argv(var)
             myenv[var[0]] = var[1]
             break
         else: n = n + 1
    return r_parse_argv(defaults, argv, i+1, options, usage)

def format_argv(var):
    if var[0] == "NET" or var[0] == "INTNET":
        net = ip.ip_network(var[1]) if var[1] != "" else defnet
        m = re.match('(\d*\.){2}(\d*)', str(net.network_address)) # trim last .0
        if m: var[1] = m.group()
        if var[0] == "NET":
            myenv["MASK"] = str(net.netmask)
            myenv["MASKb"] = "%s" % net.prefixlen
        if var[0] == "INTNET":
            myenv["INTMASK"] = str(net.netmask)
            myenv["INTMASKb"] = "%s" % net.prefixlen
    if var[0] == "NET6" or var[0] == "INTNET6":
        net6 = ip.ip_network(var[1]) if var[1] != "" else defnet6
        m = re.match('(\w*:){1,7}', str(net6.network_address)) # trim last :0
        if m: var[1] = m.group()
        if var[0] == "NET6":
            myenv["MASK6"] = str(net6.netmask)
            myenv["MASKb6"] = "%s" % net6.prefixlen
        if var[0] == "INTNET6":
            myenv["INTMASK6"] = str(net6.netmask)
            myenv["INTMASKb6"] = "%s" % net6.prefixlen
    return var

def main(argv):
    parse_args(argv)
    while myenv["SSID"] == "":
        myenv["SSID"] = input("Please set a name for the Wifi Network: ")
    while len(myenv["PAWD"]) < 8 or len(myenv["PAWD"]) > 63:
        myenv["PAWD"] = input("Please set a passphrase (8..63 characters) for the SSID " + myenv['SSID'] + ": ")
    while myenv["MODE"] not in ['a','b','g']:
        myenv["MODE"] = input("Please set a WIFI mode (a = IEEE 802.11ac, g = IEEE 802.11n; b = IEEE 802.11b) [a]: ")
        if myenv["MODE"] == "": myenv["MODE"] = 'a'
    while myenv["CTY_CODE"] == "":
        cty_code = re.match(".*_([A-Z]*)", lc.getlocale()[0]).group(1)
        if not cty_code: cty_code = re.match("[A-Z]*", lc.getlocale()).group()
        myenv["CTY_CODE"] = input("Please set the country code to use [%s]: " % cty_code)
        if myenv["CTY_CODE"] == "": myenv["CTY_CODE"] = cty_code
    while myenv["CHANNEL"] == "":
        myenv["CHANNEL"] = input("Please set the WI-FI channel to use with %s mode [0 = automatic channel selection]: " % myenv['MODE'])
        if myenv["CHANNEL"] == "": myenv["CHANNEL"] = "0"
    os.environ.update(myenv)
    write_exports(myenv)
    write_lib()

def write_exports(envdict):
    path=".hap-wiz-env.sh"
    f = open(path, "w")
    f.write("#!/usr/bin/env bash\nexport")
    for k,v in myenv.items():
        f.write(" '{}'=\"{}\"".format(k,v))
    f.close()
    os.chmod(path, 0o755)

def write_lib():
    path=".hap-wiz-lib.sh"
    f = open(path, "w")
    f.write("#!/usr/bin/env bash\n")
    f.write("function nameservers() {\n\
      ns=$1\n\
      sep=''\n\
      while [ \"$#\" -gt 1 ]; do case $2 in\n\
        \"''\"|'' );;\n\
          *)\n\
            [ $ns != '' ] && [ $ns != \"''\" ] && sep=','\n\
            ns=\"${ns}${sep}$2\";;\n\
      esac; shift; done\n\
      [ $ns != '' ] && [ $ns != \"''\" ] && echo $ns | sed -e s/,,//g -e s/,$// -e s/^,//\n\
    }\n\
")
    f.close()
    os.chmod(path, 0o755)

if __name__ == '__main__':
    main(sys.argv)
