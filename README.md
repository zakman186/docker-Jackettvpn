
# qBittorrent with WebUI and OpenVPN
Docker container which runs qBittorrent torrent client with WebUI while connecting to OpenVPN.

## Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it.
To run the container use this command:

```
$ docker run --privileged  -d \
              -v /your/docker/config/path/:/config \
              -v /your/downloads/path/:/downloads \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -p 8080:8080 \
              markusmcnugen/qbittorrentvpn
```

You must set the environment variables `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` to provide basic connection details.

As you can see, the container also expects a downloads volume to be mounted.
This is where qBittorrent will store your downloads, incomplete downloads and look for a watch directory for new .torrent files.

### Required environment options
| Variable | Function | Example |
|----------|----------|-------|
|`OPENVPN_USERNAME`|Your OpenVPN username |`OPENVPN_USERNAME=asdf`|
|`OPENVPN_PASSWORD`|Your OpenVPN password |`OPENVPN_PASSWORD=asdf`|

### Access the WebUI
But what's going on? My http://my-host:9091 isn't responding?
This is because the VPN is active, and since docker is running in a different ip range than your client the response
to your request will be treated as "non-local" traffic and therefore be routed out through the VPN interface.

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
$ cd /repo/location/docker-transmission-openvpn
$ docker build -t transmission-openvpn .
```
### Run it:
```
$ docker run --privileged  -d \
              -v /your/storage/path/:/data \
              -e "OPENVPN_PROVIDER=PIA" \
              -e "OPENVPN_CONFIG=Netherlands" \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -p 9091:9091 \
              transmission-openvpn
```

This will start a container as described in the "Run container from Docker registry" section.

