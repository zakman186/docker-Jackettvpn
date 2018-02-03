#!/bin/bash
set -x

function trap_handler
 {
     echo "[info] Shutdown detected... copying config file to /config/qbittorrent"
     yes | cp /root/.config/qBittorrent/qBittorrent.conf /config/qbittorrent/qBittorrent.conf
 }

# if config file doesnt exist then copy default config file
if [[ ! -f /config/qbittorrent/qBittorrent.conf ]]; then

	echo "[warn] qBittorrent config file does not exist, copying default settings to /config/qbittorrent"
	echo "[info] You can edit the conf file at /config/qbittorrent to change qBittorrents settings and restart the container"
	yes | cp /root/.config/qBittorrent/qBittorrent.conf /config/qbittorrent/qBittorrent.conf
	chown -R "${PUID}":"${PGID}" /config/qbittorrent
	chmod -R 775 /config/qbittorrent

else

	echo "qBittorrent config file exists in /config, copying to qbittorrent config directory"
	yes | cp /config/qbittorrent/qBittorrent.conf /root/.config/qBittorrent/qBittorrent.conf
	chmod 644 /root/.config/qBittorrent/qBittorrent.conf

fi

trap trap_handler SIGINT SIGTERM SIGHUP 

echo "[info] Starting qBittorrent daemon..."
/usr/bin/qbittorrent-nox -d
wait
