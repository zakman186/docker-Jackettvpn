#!/bin/bash
set -e

_handler() {
	echo "[warn] Shutdown detected... cleaning up real quick!" | ts '%Y-%m-%d %H:%M:%.S'
	# if config directory exists, apply permissions before exiting
	chmod -R 755 /config/qBittorrent
}

if [[ ! -e /config/qBittorrent ]]; then
	mkdir -p /config/qBittorrent/config/
	chown -R ${PUID}:${PGID} /config/qBittorrent
else
	chown -R ${PUID}:${PGID} /config/qBittorrent
fi

if [[ ! -e /config/qBittorrent/config/qBittorrent.conf ]]; then
	/bin/cp /etc/qbittorrent/qBittorrent.conf /config/qBittorrent/config/qBittorrent.conf
	chmod 755 /config/qBittorrent/config/qBittorrent.conf
	chown -R ${PUID}:${PGID} /config/qBittorrent/config/qBittorrent.conf
fi

echo "[info] Starting qBittorrent daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/bin/bash /etc/qbittorrent/qbittorrent.init start &
echo "[info] Started qBittorrent daemon..." | ts '%Y-%m-%d %H:%M:%.S'
chmod -R 755 /config/qBittorrent

child=$(pgrep -o -x qbittorrent-nox) 
echo "[info] qbittorrent-nox PID: $child" | ts '%Y-%m-%d %H:%M:%.S'

while true; do 
	if [ -e /proc/$child ]; then
		sleep 0.1
	else
		_handler
	fi
done
