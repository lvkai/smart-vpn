#!/bin/sh

if [ $# -eq 0 ]
then
    nvram set smartvpn="run"
    nvram commit
fi

if [ $(nvram get smartvpn) = "run" ]
then
    openvpn --config /jffs/smart-vpn/openvpn.conf --daemon
fi
