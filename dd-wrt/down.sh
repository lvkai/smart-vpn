#!/bin/sh

if [ -n "$SMART_VPN_DEBUG" ]
then
    set -x
fi

iptables -D POSTROUTING -t nat -o tun0 -j MASQUERADE

LOG='/tmp/smart-vpn.log'

echo "$(date +"%Y-%m-%d %H:%M:%S") --- down.sh begin." >> $LOG

#OLDGW=$(nvram get wan_gateway)

OPENVPNDEV='tun0'
#VPNGW=$(ifconfig $OPENVPNDEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)

# remove the static routes
route -n | awk '$NF ~ /$OPENVPNDEV/{print $1,$3}' | while read IP MASK 
do
    echo "$(date +"%Y-%m-%d %H:%M:%S") remove $IP from static route." >> $LOG
    route del -net $IP netmask $MASK
done

# restore dnsmasq
if [ -f /tmp/dnsmasq_options.bak ]
then
    nvram set dnsmasq_options="$(cat /tmp/dnsmasq_options.bak)"
    rm /tmp/dnsmasq_options.bak
fi

stopservice dnsmasq
startservice dnsmasq

wget -qO- "http://smartvpn.sinaapp.com/Down?id=$(nvram get SMART_VPN_UP_ID)"
nvram unset SMART_VPN_UP_ID

# clean route and verify processes
killall route.sh
killall verify.sh

# check restart or not
if [ $(nvram get smartvpn) = "run" ]
then
    echo "The VPN connection is lost. restart it now." >> $LOG
    /jffs/smart-vpn/start.sh &
fi

echo "$(date +"%Y-%m-%d %H:%M:%S") --- down.sh end." >> $LOG
echo "" >> $LOG
