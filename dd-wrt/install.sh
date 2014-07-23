#!/bin/sh

echo "checking version."
if [ -f version.txt ]
then
    OLD=$(cat version.txt)
    rm version.txt
fi
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/version.txt
NEW=$(cat version.txt)
echo "old version: $OLD."
echo "new version: $NEW."
wget -qO- "http://smartvpn.sinaapp.com/Install?old=$OLD&new=$NEW" > /dev/null

echo "removing old files."
rm -f install.sh
rm -f up.sh
rm -f down.sh
rm -f route.sh
rm -f verify.sh
rm -f start.sh
rm -f stop.sh
rm -f restart.sh

echo "downloading new files."
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/install.sh
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/up.sh
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/down.sh
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/route.sh
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/verify.sh
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/start.sh
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/stop.sh
wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/restart.sh

chmod a+x *.sh

if [ ! -f openvpn.conf ]
then
    wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/openvpn.conf
fi

if [ ! -f ca.crt ]
then
    wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/ca.crt
fi

if [ ! -f blacklist.txt ]
then
    wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/blacklist.txt
fi

if [ ! -f whitelist.txt ]
then
    wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/whitelist.txt
fi

if [ ! -f  password.txt ]
then
    wget -q http://smart-vpn.googlecode.com/svn/trunk/dd-wrt/password.txt
    chmod 600 password.txt
fi

echo "setting auto start."
nvram set rc_startup="/jffs/smart-vpn/start.sh auto"
nvram commit

echo "installation complete."
