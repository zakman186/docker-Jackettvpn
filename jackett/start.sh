#!/bin/bash
if [[ ! -e /config/Jackett ]]; then
	mkdir -p /config/Jackett
fi
chown -R ${PUID}:${PGID} /config/Jackett

# Set the rights on the /blackhole folder
chown -R ${PUID}:${PGID} /blackhole

if [ ! -e /config/Jackett/ServerConfig.json ]; then
	echo "[INFO] ServerConfig.json is missing, this is normal for the first launch! Copying template" | ts '%Y-%m-%d %H:%M:%.S'
	cp /etc/jackett/ServerConfig.json /config/Jackett/ServerConfig.json
	chmod 755 /config/Jackett/ServerConfig.json
fi

# Check for missing Group / PGID
/bin/egrep -i "^${PGID}:" /etc/passwd
if [ $? -eq 0 ]; then
	echo "A group with PGID $PGID already exists in /etc/passwd, nothing to do."
else
	echo "A group with PGID $PGID does not exist, adding a group called 'jackett' with PGID $PGID"
	groupadd -g $PGID jackett
fi

# Check for missing User / PUID
/bin/egrep -i "^${PUID}:" /etc/passwd
if [ $? -eq 0 ]; then
	echo "An user with PUID $PUID already exists in /etc/passwd, nothing to do."
else
	echo "An user with PUID $PUID does not exist, adding an user called 'jackett user' with PUID $PUID"
	useradd -c "jackett user" -g $PGID -u $PUID jackett
fi

# Set umask
export UMASK=$(echo "${UMASK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

if [[ ! -z "${UMASK}" ]]; then
	echo "[INFO] UMASK defined as '${UMASK}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] UMASK not defined (via -e UMASK), defaulting to '002'" | ts '%Y-%m-%d %H:%M:%.S'
	export UMASK="002"
fi

# Setting API Key
# An API Key is also required for setting a password
APIKey=$(cat /config/Jackett/ServerConfig.json | jq -r '.APIKey')
if [ -z ${APIKey} ]; then
	echo "[INFO] No APIKey in the ServerConfig.json, this is normal for the first launch" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[INFO] Generating new APIKey" | ts '%Y-%m-%d %H:%M:%.S'
	NewAPIKey=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
	cat /config/Jackett/ServerConfig.json | jq --arg NewKey "$NewAPIKey" '.APIKey = "\($NewKey)"' | sponge /config/Jackett/ServerConfig.json
	echo "[INFO] Generated APIKey: ${NewAPIKey}" | ts '%Y-%m-%d %H:%M:%.S'
fi

current_hash=$(cat /config/Jackett/ServerConfig.json | jq -r '.AdminPassword')

if [[ ${current_hash} == 'null' && -z "${WEBUI_PASSWORD}" ]]; then
	echo "[WARNING] There is no password set via Jackett's web interface or as an environment variable!" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[WARNING] Anyone on your network could access Jackett without authentication!" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[WARNING] Or even the whole world if you did port-fortwarding!" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[WARNING] It's adviced to set one via either the web interface or as environment variable" | ts '%Y-%m-%d %H:%M:%.S'
fi

if [ ! -z "${WEBUI_PASSWORD}" ]; then
	# Test to see if the password has valid characters, prinf or iconv exists with code 1 if there are invalid characters
	printf "${WEBUI_PASSWORD}" > /dev/null 2>&1
	if [[ $? -eq 1 ]]; then
		echo "[ERROR] Password contains unsupported characters." | ts '%Y-%m-%d %H:%M:%.S'
		exit 1
	fi
	printf "${WEBUI_PASSWORD}" | iconv -t utf16le > /dev/null 2>&1
	if [[ $? -eq 1 ]]; then
		echo "[ERROR] Password contains unsupported characters." | ts '%Y-%m-%d %H:%M:%.S'
		exit 1
	fi
	echo "[INFO] Generating password hash" | ts '%Y-%m-%d %H:%M:%.S'
	APIKey=$(cat /config/Jackett/ServerConfig.json | jq -r '.APIKey')
	password_apikey=$(printf "${WEBUI_PASSWORD}"${APIKey})
	password_hash=$(printf ${password_apikey} | iconv -t utf16le | sha512sum | cut -c-128)

	if [ ! ${current_hash} == ${password_hash} ]; then
		cat /config/Jackett/ServerConfig.json | jq --arg Password "$password_hash" '.AdminPassword = "\($Password)"' | sponge /config/Jackett/ServerConfig.json
	else
		echo "[INFO] Password hashes match, nothing to change." | ts '%Y-%m-%d %H:%M:%.S'
	fi
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

echo "[INFO] Starting Jackett daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/bin/bash /etc/jackett/jackett.init start &
chmod -R 755 /config/Jackett

sleep 1
jackettpid=$(pgrep -o -x jackett) 
echo "[INFO] Jackett PID: $jackettpid" | ts '%Y-%m-%d %H:%M:%.S'

if [ -e /proc/$jackettpid ]; then
	if [[ -e /config/Jackett/Logs/log.txt ]]; then
		chmod 775 /config/Jackett/Logs/log.txt
	fi
	
	HOST=${HEALTH_CHECK_HOST}
	DEFAULT_HOST="one.one.one.one"
	INTERVAL=${HEALTH_CHECK_INTERVAL}
	DEFAULT_INTERVAL=300
	
	if [[ -z "$HOST" ]]; then
		echo "[INFO] HEALTH_CHECK_HOST is not set. For now using default host ${DEFAULT_HOST}" | ts '%Y-%m-%d %H:%M:%.S'
		HOST=${DEFAULT_HOST}
	fi

	if [[ -z "$HEALTH_CHECK_INTERVAL" ]]; then
		echo "[INFO] HEALTH_CHECK_INTERVAL is not set. For now using default interval of ${DEFAULT_INTERVAL}" | ts '%Y-%m-%d %H:%M:%.S'
		INTERVAL=${DEFAULT_INTERVAL}
	fi
	
	if [[ -z "$HEALTH_CHECK_SILENT" ]]; then
		echo "[INFO] HEALTH_CHECK_SILENT is not set. Because this variable is not set, it will be supressed by default" | ts '%Y-%m-%d %H:%M:%.S'
		HEALTH_CHECK_SILENT=1
	fi

	while true; do
	
		# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for docker health checks,
		# therefore we use this script to catch error code 2
		ping -c 1 $HOST > /dev/null 2>&1
		STATUS=$?
		if [[ ${STATUS} -ne 0 ]]; then
			echo "[ERROR] Network is down, exiting this Docker" | ts '%Y-%m-%d %H:%M:%.S'
			exit 1
		fi
		if [ ! "$HEALTH_CHECK_SILENT" -eq 1 ]; then
			echo "[INFO] Network is up" | ts '%Y-%m-%d %H:%M:%.S'
		fi
		sleep ${INTERVAL}

	done
else
	echo "[ERROR] Jackett failed to start!" | ts '%Y-%m-%d %H:%M:%.S'
fi
