 #!/bin/bash

 function trap_handler
 {
     echo "Shutdown detected... copying config file to /config/qbittorrent"
     cp /home/$USER/.config/qBittorrent/qBittorrent.conf /config/qbittorrent/qBittorrent.conf
 }

 trap trap_handler SIGINT SIGTERM SIGHUP 

 while true
 do
      sleep 10
 done
