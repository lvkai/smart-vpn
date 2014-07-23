#!/bin/sh

if [ -n "$SMART_VPN_DEBUG" ]
then
    set -x
fi

iptables -A POSTROUTING -t nat -o tun0 -j MASQUERADE

LOG='/tmp/smart-vpn.log'

echo "$(date +"%Y-%m-%d %H:%M:%S") --- up.sh begin." >> $LOG

# get default gateway
OLDGW=$(nvram get wan_gateway)

if [ -z "$OLDGW" ]
then
    echo "$(date +"%Y-%m-%d %H:%M:%S") There is no network, please check it." >> $LOG
    exit 0
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") The local gateway is $OLDGW" >> $LOG
fi

# get vpn gateway
OPENVPNDEV='tun0'
VPNGW=$(ifconfig $OPENVPNDEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
VPNLOG=$(grep log /jffs/smart-vpn/openvpn.conf | cut -d' ' -f2)
VPNIP=$(grep -Eo "UDPv4 link remote: ([0-9.]+)" $VPNLOG | cut -d' ' -f4)

if [ "echo $VPNGW | cut -b1-8" = "ifconfig" ]
then
    echo "$(date +"%Y-%m-%d %H:%M:%S") The vpn is not connected, please check it." >> $LOG
    exit 0
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") The remote gateway is $VPNGW" >> $LOG
fi

SMART_VPN_UP_ID=$(wget -qO- "http://smartvpn.sinaapp.com/Up?remote=$VPNIP")
nvram set SMART_VPN_UP_ID="$SMART_VPN_UP_ID"

# add the google DNS and OpenDNS
echo "$(date +"%Y-%m-%d %H:%M:%S") Add Google DNS and OpenDNS to gateway $VPNGW" >> $LOG
route add -host 8.8.8.8 gw $VPNGW
route add -host 8.8.4.4 gw $VPNGW
route add -host 208.67.220.220 gw $VPNGW
route add -host 208.67.222.222 gw $VPNGW

echo "$(date +"%Y-%m-%d %H:%M:%S") --- up.sh end." >> $LOG
echo "" >> $LOG

/jffs/smart-vpn/route.sh &
