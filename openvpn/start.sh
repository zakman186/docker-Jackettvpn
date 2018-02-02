#!/bin/sh
set -x

# create directory to store openvpn config files
mkdir -p /config/openvpn

#Locate first file with .ovpn extension
export VPN_CONFIG=$(find /config/openvpn -maxdepth 1 -name "*.ovpn" -print -quit)

if [[ -z "${VPN_CONFIG}" ]]; then
		echo "No ovpn file found. Add one to /config/openvpon abd restart this container, exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
fi

# add OpenVPN user/pass
if [ "${OPENVPN_USERNAME}" = "**None**" ] || [ "${OPENVPN_PASSWORD}" = "**None**" ] ; then
 echo "OpenVPN credentials not set. Exiting."
 exit 1
else
  echo "Setting OPENVPN credentials..."
  mkdir -p /config
  echo $OPENVPN_USERNAME > /config/openvpn-credentials.txt
  echo $OPENVPN_PASSWORD >> /config/openvpn-credentials.txt
  chmod 600 /config/openvpn-credentials.txt
fi

exec openvpn --config "$VPN_CONFIG"
