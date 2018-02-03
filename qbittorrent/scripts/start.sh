#!/bin/bash
set -x

function trap_handler
{
	echo "[info] Shutdown detected... copying config file to /config/qbittorrent" | ts '%Y-%m-%d %H:%M:%.S'
	yes | cp /root/.config/qBittorrent/qBittorrent.conf /config/qbittorrent/qBittorrent.conf
}

# Make qbittorrent config directory
mkdir -p /config/qbittorrent

# if config file doesnt exist then copy default config file
if [[ ! -f /config/qbittorrent/qBittorrent.conf ]]; then
	echo "[warn] qBittorrent config file does not exist, copying default settings to /config/qbittorrent" | ts '%Y-%m-%d %H:%M:%.S'
	echo "[info] You can edit the conf file at /config/qbittorrent to change qBittorrents settings and restart the container" | ts '%Y-%m-%d %H:%M:%.S'
	yes | cp /etc/qbittorrent/default/qBittorrent.conf /config/qbittorrent/qBittorrent.conf
	yes | cp /config/qbittorrent/qBittorrent.conf /root/.config/qBittorrent/qBittorrent.conf
	chown -R "${PUID}":"${PGID}" /config/qbittorrent
	chmod -R 775 /config/qbittorrent
	chmod 644 /root/.config/qBittorrent/qBittorrent.conf
# Else create directories and copy conf from config volume
else
	echo "qBittorrent config file exists in /config, copying to qbittorrent config directory" | ts '%Y-%m-%d %H:%M:%.S'
	mkdir -p /root/.config/qBittorrent/
	yes | cp /config/qbittorrent/qBittorrent.conf /root/.config/qBittorrent/qBittorrent.conf
	chmod 644 /root/.config/qBittorrent/qBittorrent.conf
fi

trap trap_handler SIGINT SIGTERM SIGHUP 

echo "[info] Starting qBittorrent daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/usr/bin/qbittorrent-nox -d 
