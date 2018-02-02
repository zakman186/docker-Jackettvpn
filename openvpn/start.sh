#!/bin/sh
set -x

# create directory to store openvpn config files
if [ ! -d "/config/openvpn" ]; then
  mkdir -p /config/openvpn
fi

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
  echo $OPENVPN_USERNAME > /config/openvpn/credentials.conf
  echo $OPENVPN_PASSWORD >> /config/openvpn/credentials.conf
  chmod 775 /config/openvpn/credentials.conf
fi

exec openvpn --config "$VPN_CONFIG"
