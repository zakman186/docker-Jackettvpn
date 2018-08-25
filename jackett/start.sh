#!/bin/bash
if [[ ! -e /config/Jackett ]]; then
	mkdir -p /config/Jackett
fi
chown -R ${PUID}:${PGID} /config/Jackett

if [[ ! -e /config/Jackett/ServerConfig.json ]]; then
	/bin/cp /etc/jackett/ServerConfig.json /config/Jackett/ServerConfig.json
	chmod 755 /config/Jackett/ServerConfig.json
fi

# Set Jackett WebUI Port
if [ ! -z "${WEBUI_PORT}" ]; then
	webui_port_exist=$(cat /config/Jackett/ServerConfig.json | grep -m 1 "  \"Port\": ${WEBUI_PORT},")
	if [[ -z "${webui_port_exist}" ]]; then
		webui_exist=$(cat /config/Jackett/ServerConfig.json | grep -m 1 '  \"Port\": ')
		if [[ ! -z "${webui_exist}" ]]; then
			# Get line number of WebUI Port
			LINE_NUM=$(grep -Fn -m 1 '  "Port":' /config/Jackett/ServerConfig.json | cut -d: -f 1)
			sed -i "${LINE_NUM}s@.*@  \"Port\": ${WEBUI_PORT},@" /config/Jackett/ServerConfig.json
		else
			echo "  \"Port\": ${WEBUI_PORT}," >> /config/Jackett/ServerConfig.json
		fi
	fi
fi

echo "[info] Starting Jackett daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/bin/bash /etc/jackett/jackett.init start &
chmod -R 755 /config/Jackett

sleep 1
jackettpid=$(pgrep -o -x mono) 
echo "[info] Jackett PID: $jackettpid" | ts '%Y-%m-%d %H:%M:%.S'

if [ -e /proc/$jackettpid ]; then
	if [[ -e /config/Jackett/log.txt ]]; then
		chmod 775 /config/Jackett/log.txt
	fi
	sleep infinity
else
	echo "Jackett failed to start!"
fi