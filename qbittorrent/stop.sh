 #!/bin/bash

 function trap_handler
 {
     echo "[info] Shutdown detected... copying config file to /config/qbittorrent"
     cp /root/.config/qBittorrent/qBittorrent.conf /config/qbittorrent/qBittorrent.conf
     exit 0
 }

 trap trap_handler SIGINT SIGTERM SIGHUP 

 while true
 do
      sleep 10
 done
