#!/bin/sh

if [ -n "$SMART_VPN_DEBUG" ]
then
    set -x
fi

LOG='/tmp/smart-vpn.log'

echo "$(date +"%Y-%m-%d %H:%M:%S") verify.sh begin." >> $LOG

# verify blacklist
echo "verifying blacklist" >> $LOG
grep -v '^#' /jffs/smart-vpn/blacklist.txt | grep -v '^\s*$' | while read DN
do
    ROUTER=$(traceroute $DN | grep '^ 1  ' | awk -F ' ' '{print $2}')
    if [ $ROUTER = "localhost" ]
    then
        echo "$DN route correct." >> $LOG
    else
        echo "$DN route wrong." >> $LOG
    fi
done

echo "" >> $LOG

OLDPW=$(nvram get wan_gateway)

# verify whitelist
echo "verifying whitelist" >> $LOG
grep -v '^#' /jffs/smart-vpn/whitelist.txt | grep -v '^\s*$' | while read DN
do
    ROUTER=$(traceroute $DN | grep '^ 1  ' | awk -F ' ' '{print $2}')
    if [ $ROUTER = $OLDGW ]
    then
        echo "$DN route correct." >> $LOG
    else
        echo "$DN route wrong." >> $LOG
    fi
done

# end
echo "$(date +"%Y-%m-%d %H:%M:%S") verify.sh end." >> $LOG
echo "" >> $LOG
