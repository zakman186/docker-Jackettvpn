#!/bin/bash
set -e

_handler() {
	echo "[warn] Shutdown detected... cleaning up real quick!" | ts '%Y-%m-%d %H:%M:%.S'
	# if config directory exists, apply permissions before exiting
	if [[ -e /config/qBittorrent ]]; then
		echo "[info] qBittorrent directory exists in /config, applying ownership and permissions before exit" | ts '%Y-%m-%d %H:%M:%.S'
		chmod -R 755 /config/qBittorrent
		chown -R 99:100 /config/qBittorrent
	fi
}

trap _handler SIGINT SIGTERM SIGHUP 

echo "[info] Starting qBittorrent daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/usr/bin/qbittorrent-nox --profile=/config &

child=$(pgrep -o -x qbittorrent-nox) 
wait "$child"
