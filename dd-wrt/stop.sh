#!/bin/sh

nvram unset smartvpn
nvram commit

killall openvpn
