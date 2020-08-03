#!/bin/bash
# Forked from binhex's OpenVPN dockers
set -e

# check for presence of network interface docker0
check_network=$(ifconfig | grep docker0 || true)

# if network interface docker0 is present then we are running in host mode and thus must exit
if [[ ! -z "${check_network}" ]]; then
	echo "[ERROR] Network type detected as 'Host', this will cause major issues, please stop the container and switch back to 'Bridge' mode" | ts '%Y-%m-%d %H:%M:%.S'
	# Sleep so it wont 'spam restart'
	sleep 10
	exit 1
fi

export VPN_ENABLED=$(echo "${VPN_ENABLED}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_ENABLED}" ]]; then
	echo "[INFO] VPN_ENABLED defined as '${VPN_ENABLED}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[WARNING] VPN_ENABLED not defined,(via -e VPN_ENABLED), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
	export VPN_ENABLED="yes"
fi

export DISABLE_IPV6=$(echo "${DISABLE_IPV6,,}")
echo "[INFO] DISABLE_IPV6 is set to '${DISABLE_IPV6}'" | ts '%Y-%m-%d %H:%M:%.S'
if [[ $DISABLE_IPV6 == "1" || $DISABLE_IPV6 == "true" || $DISABLE_IPV6 == "yes" || $DISABLE_IPV6 == "" ]]; then
	echo "[INFO] Disabling IPv6 in sysctl" | ts '%Y-%m-%d %H:%M:%.S'
	sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
else
	echo "[INFO] Enabling IPv6 in sysctl" | ts '%Y-%m-%d %H:%M:%.S'
	sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
fi

if [[ $VPN_ENABLED == "yes" ]]; then
	# Create the directory to store wireguard config files
	mkdir -p /config/wireguard
	# Set permmissions and owner for files in /config/wireguard directory
	set +e
	chown -R "${PUID}":"${PGID}" "/config/wireguard" &> /dev/null
	exit_code_chown=$?
	chmod -R 755 "/config/wireguard" &> /dev/null
	exit_code_chmod=$?
	set -e
	if (( ${exit_code_chown} != 0 || ${exit_code_chmod} != 0 )); then
		echo "[WARNING] Unable to chown/chmod /config/wireguard/, assuming SMB mountpoint" | ts '%Y-%m-%d %H:%M:%.S'
	fi

	# Wildcard search for wireguard config files (match on first result)
	export VPN_CONFIG=$(find /config/wireguard -maxdepth 1 -name "*.conf" -print -quit)
	
	# If conf file not found in /config/wireguard then exit
	if [[ -z "${VPN_CONFIG}" ]]; then
		echo "[ERROR] No wireguard config file found in /config/wireguard/. Please download one from your VPN provider and restart this container. Make sure the file extension is '.conf'" | ts '%Y-%m-%d %H:%M:%.S'
		# Sleep so it wont 'spam restart'
		sleep 10
		exit 1
	fi

	echo "[INFO] WireGuard config file is found at ${VPN_CONFIG}" | ts '%Y-%m-%d %H:%M:%.S'

	# convert CRLF (windows) to LF (unix) for ovpn
	/usr/bin/dos2unix "${VPN_CONFIG}" 1> /dev/null
	
	# parse values from ovpn file
	export vpn_remote_line=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '(?<=^Endpoint\s)[^\n\r]+' | sed -e 's~^[=\ ]*~~')
	if [[ ! -z "${vpn_remote_line}" ]]; then
		echo "[INFO] VPN remote line defined as '${vpn_remote_line}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[ERROR] VPN configuration file ${VPN_CONFIG} does not contain 'remote' line, showing contents of file before exit..." | ts '%Y-%m-%d %H:%M:%.S'
		cat "${VPN_CONFIG}"
		# Sleep so it wont 'spam restart'
		sleep 10
		exit 1
	fi
	export VPN_REMOTE=$(echo "${vpn_remote_line}" | grep -P -o -m 1 '^[^:\r\n]+')
	if [[ ! -z "${VPN_REMOTE}" ]]; then
		echo "[INFO] VPN_REMOTE defined as '${VPN_REMOTE}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[ERROR] VPN_REMOTE not found in ${VPN_CONFIG}, exiting..." | ts '%Y-%m-%d %H:%M:%.S'
		# Sleep so it wont 'spam restart'
		sleep 10
		exit 1
	fi
	export VPN_PORT=$(echo "${vpn_remote_line}" | grep -P -o -m 1 '(?<=:)\d{2,5}(?=:)?+')
	if [[ ! -z "${VPN_PORT}" ]]; then
		echo "[INFO] VPN_PORT defined as '${VPN_PORT}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[ERROR] VPN_PORT not found in ${VPN_CONFIG}, exiting..." | ts '%Y-%m-%d %H:%M:%.S'
		# Sleep so it wont 'spam restart'
		sleep 10
		exit 1
	fi
	
	export VPN_PROTOCOL="udp"
	
	export VPN_DEVICE_TYPE="wg0"

	# get values from env vars as defined by user
	export LAN_NETWORK=$(echo "${LAN_NETWORK}")
	if [[ ! -z "${LAN_NETWORK}" ]]; then
		echo "[INFO] LAN_NETWORK defined as '${LAN_NETWORK}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[ERROR] LAN_NETWORK not defined (via -e LAN_NETWORK), exiting..." | ts '%Y-%m-%d %H:%M:%.S'
		# Sleep so it wont 'spam restart'
		sleep 10
		exit 1
	fi

	export NAME_SERVERS=$(echo "${NAME_SERVERS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${NAME_SERVERS}" ]]; then
		echo "[INFO] NAME_SERVERS defined as '${NAME_SERVERS}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[WARNING] NAME_SERVERS not defined (via -e NAME_SERVERS), defaulting to CloudFlare and Google name servers" | ts '%Y-%m-%d %H:%M:%.S'
		export NAME_SERVERS="1.1.1.1,8.8.8.8,1.0.0.1,8.8.4.4"
	fi
elif [[ $VPN_ENABLED == "no" ]]; then
	echo "[WARNING] !!IMPORTANT!! You have set the VPN to disabled, you will NOT be secure!" | ts '%Y-%m-%d %H:%M:%.S'
fi

# split comma seperated string into list from NAME_SERVERS env variable
IFS=',' read -ra name_server_list <<< "${NAME_SERVERS}"

# process name servers in the list
for name_server_item in "${name_server_list[@]}"; do
	# strip whitespace from start and end of lan_network_item
	name_server_item=$(echo "${name_server_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

	echo "[INFO] Adding ${name_server_item} to resolv.conf" | ts '%Y-%m-%d %H:%M:%.S'
	echo "nameserver ${name_server_item}" >> /etc/resolv.conf
done

if [[ -z "${PUID}" ]]; then
	echo "[INFO] PUID not defined. Defaulting to root user" | ts '%Y-%m-%d %H:%M:%.S'
	export PUID="root"
fi

if [[ -z "${PGID}" ]]; then
	echo "[INFO] PGID not defined. Defaulting to root group" | ts '%Y-%m-%d %H:%M:%.S'
	export PGID="root"
fi

if [[ $VPN_ENABLED == "yes" ]]; then
	echo "[INFO] Starting WireGuard..." | ts '%Y-%m-%d %H:%M:%.S'
	wg-quick up $VPN_CONFIG
	#exec /bin/bash /etc/openvpn/openvpn.init start &
	exec /bin/bash /etc/jackett/iptables.sh
else
	exec /bin/bash /etc/jackett/start.sh
fi
