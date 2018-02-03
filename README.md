
# qBittorrent with WebUI and OpenVPN
Docker container which runs a headless qBittorrent client with WebUI while connecting to OpenVPN.

## Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it.
To run the container use this command:

```
$ docker run --privileged  -d \
              -v /your/docker/config/path/:/config \
              -v /your/downloads/path/:/downloads \
              -e "OPENVPN_USERNAME=username" \
              -e "OPENVPN_PASSWORD=password" \
              -e "LAN_NETWORK=192.168.1.0/24" \
              -e "NAME_SERVERS=8.8.8.8,8.8.4.4" \
              -e "PUID=99" \
              -e "PGID=100" \
              -p 8080:8080 \
              -p 8999:8999 \
              markusmcnugen/qbittorrentvpn
```

You must set the environment variables `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` to provide basic connection details.

As you can see, the container also expects a downloads volume to be mounted.
This is where qBittorrent will store your downloads, incomplete downloads and look for a watch directory for new .torrent files.

### Required environment options
| Variable | Function | Example |
|----------|----------|-------|
|`OPENVPN_USERNAME`|Your OpenVPN username |`OPENVPN_USERNAME=username`|
|`OPENVPN_PASSWORD`|Your OpenVPN password |`OPENVPN_PASSWORD=password`|
|`LAN_NETWORK`|Local Network with CIDR notation |`OPENVPN_PASSWORD=192.168.1.0/24`|
|`NAME_SERVERS`|Comma delimited name servers |`NAME_SERVERS=8.8.8.8,8.8.4.4`|
|`PUID`|UID applied to config files |`PUID=99`|
|`PGID`|GID applied to config files |`PGID=100`|

### Access the WebUI
Access http://IPADDRESS:8080 from a browser on the same network

### Known issues
Some have encountered problems with DNS resolving inside the docker container.
This causes trouble because OpenVPN will not be able to resolve the host to connect to.
If you have this problem use dockers --dns flag to override the resolv.conf of the container.
For example use googles dns servers by adding --dns 8.8.8.8 --dns 8.8.4.4 as parameters to the usual run command.

If you are having issues with this container please submit an issue on GitHub.
Please provide logs, docker version and other information that can simplify reproducing the issue.
Using the latest stable verison of Docker is always recommended. Support for older version is on a best-effort basis.

## Building the container yourself
To build this container, clone the repository and cd into it.

### Build it:
```
$ cd /repo/location/qbittorrentvpn
$ docker build -t qbittorrentvpn .
```
### Run it:
```
$ docker run --privileged  -d \
              -v /your/docker/config/path/:/config \
              -v /your/downloads/path/:/downloads \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -e "LAN_NETWORK=192.168.1.0/24" \
              -e "NAME_SERVERS=8.8.8.8,8.8.4.4" \
              -e "PUID=99" \
              -e "PGID=100" \
              -p 8080:8080 \
              -p 8999:8999 \
              qbittorrentvpn
```

This will start a container as described in the "Run container from Docker registry" section.

