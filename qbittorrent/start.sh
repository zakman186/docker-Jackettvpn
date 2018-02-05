#!/bin/bash
set -e

_handler() {
	echo "[warn] Shutdown detected... cleaning up real quick!" | ts '%Y-%m-%d %H:%M:%.S'
	# if config directory exists, apply permissions before exiting
	qbpid=$(pgrep -o -x qbittorrent-nox)
	if [[ ! -z $qbpid ]]; then
		echo "[warn] qBittorrent still running... shutting down now" | ts '%Y-%m-%d %H:%M:%.S'
		kill -9 $qbpid
	fi
	
	if [[ -e /config/qBittorrent ]]; then
		echo "[info] qBittorrent directory exists in /config, applying ownership and permissions before exit" | ts '%Y-%m-%d %H:%M:%.S'
		chmod -R 755 /config/qBittorrent
		chown -R $PUID:$PGID /config/qBittorrent
	fi
}

trap _handler SIGINT SIGTERM SIGHUP 

if [[ ! -e /config/qBittorrent ]]; then
	mkdir -p /config/qBittorrent/config/
	chown -R ${PUID}:${PGID} /config/qBittorrent
else
	chown -R ${PUID}:${PGID} /config/qBittorrent
fi

if [[ ! -e /config/qBittorrent/config/qBittorrent.conf ]]; then
	/bin/cp /etc/qbittorrent/qBittorrent.conf /config/qBittorrent/config/qBittorrent.conf
	chmod 755 /config/qBittorrent/config/qBittorrent.conf
fi

echo "[info] Starting qBittorrent daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/bin/bash /etc/qbittorrent/qbittorrent.init start &
chmod -R 755 /config/qBittorrent

sleep 1

echo "[info] qBittorrent PID: $child" | ts '%Y-%m-%d %H:%M:%.S'

if [ -e /proc/$child ]; then
	this=$(echo $$) 
	wait "$this"
else
	echo "qBittorrent failed to start!" || exit 2
fi
