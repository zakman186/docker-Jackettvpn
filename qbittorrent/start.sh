#!/bin/bash

# if config file doesnt exist then copy default config file
if [[ ! -f /config/qbittorrent/qBittorrent.conf ]]; then

	echo "qBittorrent config file does not exist, copying default settings to /config/qBittorrent"
	echo "You can edit the conf file at /config/qBittorrent to change qBittorrents settings while docker if offline"
	yes | cp /home/$USER/.config/qBittorrent/qBittorrent.conf /config/qbittorrent/qBittorrent.conf
	chown -R "${PUID}":"${PGID}" /config/qbittorrent
	chmod -R 775 /config/qbittorrent

else

	echo "qBittorrent config file exists in /config, copying to qbittorrent config directory"
	yes | cp /config/qbittorrent/qBittorrent.conf /home/$USER/.config/qBittorrent/qBittorrent.conf
	chmod 644 /home/$USER/.config/qBittorrent/qBittorrent.conf

fi

echo "Starting qBittorrent daemon..."
/usr/bin/qbittorrent-nox -d
