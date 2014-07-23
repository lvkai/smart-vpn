#!/bin/sh

if [ -n "$SMART_VPN_DEBUG" ]
then
    set -x
fi

# backup and restore DNSMasq Options
if [ ! -f /tmp/dnsmasq_options.bak ]
then
    nvram get dnsmasq_options > /tmp/dnsmasq_options.bak
fi
cp /tmp/dnsmasq_options.bak /tmp/dnsmasq_options.txt

BLACKLIST=$(grep -o "[^ ]\+\( \+[^ ]\+\)*" /jffs/smart-vpn/blacklist.txt | grep -v '^#' | grep .) 
for DN in $BLACKLIST
do
    echo "server=/$DN/8.8.8.8" >> /tmp/dnsmasq_options.txt
done

nvram set dnsmasq_options="$(cat /tmp/dnsmasq_options.txt)"

stopservice dnsmasq
startservice dnsmasq

iptables -A POSTROUTING -t nat -o tun0 -j MASQUERADE

LOG='/tmp/smart-vpn.log'

echo "$(date +"%Y-%m-%d %H:%M:%S") route.sh begin." >> $LOG

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

# add static routes
echo "$(date +"%Y-%m-%d %H:%M:%S") Adding static routes, this may take a while." >> $LOG

URL="http://smartvpn.sinaapp.com/Login?remote=$VPNIP"
SESSIONID=$(wget -qO- $URL)

# submit the domain names for quick black route, max 5 in a group
URL="http://smartvpn.sinaapp.com/QuickBlackList;jsessionid=$SESSIONID?"
counter=0
for DN in $BLACKLIST
do
    URL="$URL&dn=$DN"
    counter=$counter+1
    if [ $((counter%5)) -eq 0 ]
    then
        wget -qO- $URL
        URL="http://smartvpn.sinaapp.com/QuickBlackList;jsessionid=$SESSIONID?"
    fi
done

if [ $((count%5)) -ne 0 ]                                                   
then                                                                        
    wget -qO- $URL                                                          
fi

# get the quick black route
URL="http://smartvpn.sinaapp.com/QuickBlackRoute;jsessionid=$SESSIONID"
wget -qO- $URL | while read NET
do
    echo "route add $NET gw $VPNGW" >> $LOG
    route add $NET gw $VPNGW
done

# refine the black route
for DN in $BLACKLIST
do
    URL="http://smartvpn.sinaapp.com/RefineBlackRoute;jsessionid=$SESSIONID?dn=$DN"
    first=0
    for IP in $(nslookup $DN 8.8.8.8 | grep '^Address ' | sed '1d' | awk -F ' ' '{print $3}' | grep -v ':')
    do
        if [ $first -eq 0 ]
        then
            echo "address=/$DN/$IP" >> /tmp/dnsmasq_options.txt
        fi
        first=1
        URL="$URL&ip=$IP"
    done
    wget -qO- $URL | while read NET
    do
        echo "route add $NET gw $VPNGW" >> $LOG
        route add $NET gw $VPNGW
    done
done

nvram set dnsmasq_options="$(cat /tmp/dnsmasq_options.txt)"

stopservice dnsmasq
startservice dnsmasq

# deal with the white route
WHITELIST=$(grep -o "[^ ]\+\( \+[^ ]\+\)*" /jffs/smart-vpn/whitelist.txt | grep -v '^#' | grep .)
for DN in $WHITELIST
do
    URL="http://smartvpn.sinaapp.com/WhiteRoute;jsessionid=$SESSIONID?dn=$DN"
    for IP in $(nslookup $DN 8.8.8.8 | grep '^Address ' | sed '1d' | awk -F " " '{print $3}' | grep -v ":")
    do
        URL="$URL&ip=$IP"
    done
    wget -qO- $URL | while read NET
    do
        echo "route add $NET gw $OLDGW" >> $LOG
        route add $NET gw $OLDGW
    done
done


# logout
URL="http://smartvpn.sinaapp.com/Logout;jsessionid=$SESSIONID"
wget -qO- $URL

# end
echo "$(date +"%Y-%m-%d %H:%M:%S") route.sh end." >> $LOG
echo "" >> $LOG

/jffs/smart-vpn/verify.sh &
