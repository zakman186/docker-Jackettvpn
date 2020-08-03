[preview]: https://raw.githubusercontent.com/DyonR/docker-templates/master/Screenshots/jackettvpn/jackettvpn-mainpage.png "Jackett Preview"

# [Jackett](https://github.com/Jackett/Jackett) and OpenVPN
![Docker Pulls](https://img.shields.io/docker/pulls/dyonr/jackettvpn)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/dyonr/jackettvpn/latest)  

Docker container which runs the latest headless [Jackett](https://github.com/Jackett/Jackett) Server while connecting to OpenVPN with iptables killswitch to prevent IP leakage when the tunnel goes down.


![alt text][preview]

## Docker Features
* Base: Ubuntu 18.04
* Latest [Jackett](https://github.com/Jackett/Jackett)
* Selectively enable or disable OpenVPN support
* IP tables kill switch to prevent IP leaking when VPN connection fails
* Specify name servers to add to container
* Configure UID and GID for config files and blackhole for Jackett
* Created with [Unraid](https://unraid.net/) in mind

# Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it.
To run the container use this command:

```
$ docker run --privileged  -d \
              -v /your/config/path/:/config \
              -v /your/downloads/path/:/blackhole \
              -e "VPN_ENABLED=yes" \
              -e "LAN_NETWORK=192.168.0.0/24" \
              -e "NAME_SERVERS=1.1.1.1,1.0.0.1" \
              -p 9117:9117 \
              --restart unless-stopped \
              dyonr/jackettvpn
```

# Variables, Volumes, and Ports
## Environment Variables
| Variable | Required | Function | Example | Default |
|----------|----------|----------|----------|----------|
|`VPN_ENABLED`| Yes | Enable VPN? (yes/no)|`VPN_ENABLED=yes`|`yes`||
|`VPN_USERNAME`| No | If username and password provided, configures ovpn file automatically |`VPN_USERNAME=ad8f64c02a2de`||
|`VPN_PASSWORD`| No | If username and password provided, configures ovpn file automatically |`VPN_PASSWORD=ac98df79ed7fb`||
|`WEBUI_PASSWORD`| Yes | The password used to protect/access Jackett's web interface |`WEBUI_PASSWORD=RJayoLnKPjeyHbo-_ziH`||
|`LAN_NETWORK`| Yes (atleast one) | Comma delimited local Network's with CIDR notation |`LAN_NETWORK=192.168.0.0/24,10.10.0.0/24`||
|`NAME_SERVERS`| No | Comma delimited name servers |`NAME_SERVERS=1.1.1.1,1.0.0.1`|`1.1.1.1,1.0.0.1`|
|`PUID`| No | UID applied to config files and blackhole |`PUID=99`|`99`|
|`PGID`| No | GID applied to config files and blackhole |`PGID=100`|`100`|
|`UMASK`| No | |`UMASK=002`|`002`|
|`WEBUI_PORT`| No | Sets the port of the Jackett server in the ServerConfig.json, needs to match the **exposed port** in the Dockerfile  |`WEBUI_PORT=9117`|`9117`|
|`HEALTH_CHECK_HOST`| No |This is the host or IP that the healthcheck script will use to check an active connection|`HEALTH_CHECK_HOST=one.one.one.one`|`one.one.one.one`|
|`HEALTH_CHECK_INTERVAL`| No |This is the time in seconds that the container waits to see if the internet connection still works (check if VPN died)|`HEALTH_CHECK_INTERVAL=300`|`300`|
|`HEALTH_CHECK_SILENT`| No |Set to `1` to supress the 'Network is up' message. Defaults to `1` if unset.|`HEALTH_CHECK_SILENT=1`|`1`|
|`DISABLE_IPV6`\*| No |Setting the value of this to `0` will **enable** IPv6 in sysctl. `1` will disable IPv6 in sysctl.|`DISABLE_IPV6=1`|`1`|
|`ADDITIONAL_PORTS`| No |Adding a comma delimited list of ports will allow these ports via the iptables script.|`ADDITIONAL_PORTS=1234,8112`||

\*This option was initially added as a way to fix problems with VPN providers that support IPv6 and might not work at all. I am unable to test this since my VPN provider does not support IPv6, nor I have an IPv6 connection.


## Volumes
| Volume | Required | Function | Example |
|----------|----------|----------|----------|
| `config` | Yes | Jackett and OpenVPN config files | `/your/config/path/:/config`|
| `blackhole` | No | Default blackhole path for saving magnet links | `/your/blackhole/path/:/blackhole`|

## Ports
| Port | Proto | Required | Function | Example |
|----------|----------|----------|----------|----------|
| `9117` | TCP | Yes | Jackett WebUI | `9117:9117`|

# Access the WebUI
Access http://IPADDRESS:PORT from a browser on the same network. (for example: http://192.168.0.90:9117)

## Default Info
API Keys are randomly generated the first time that Jackett starts up. There is no Web UI password configured. This can be done manually from the Web UI

| Credential | Default Value |
|----------|----------|
|`API Key`| Randomly generated |
|`WebUI Password`| No password |

# How to use OpenVPN
The container will fail to boot if `VPN_ENABLED` is set to yes or empty and a .ovpn is not present in the /config/openvpn directory. Drop a .ovpn file from your VPN provider into /config/openvpn and start the container again. You may need to edit the ovpn configuration file to load your VPN credentials from a file by setting `auth-user-pass`.

**Note:** The script will use the first ovpn file it finds in the /config/openvpn directory. Adding multiple ovpn files will not start multiple VPN connections.

## Example auth-user-pass option
`auth-user-pass credentials.conf`

## Example credentials.conf
```
username
password
```

## PUID/PGID
User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:

```
id <username>
```

## Known issue IPv6
There is a known issue with VPN providers that support IPv6.  
To workaround this issue, you need to add the folling lines to your .ovpn file:
```
pull-filter ignore 'route-ipv6'
pull-filter ignore 'ifconfig-ipv6'
```
Thanks to [Technikte](https://github.com/Technikte) in [Issue #19](https://github.com/DyonR/docker-Jackettvpn/issues/19).

# Issues
If you are having issues with this container please submit an issue on GitHub.
Please provide logs, docker version and other information that can simplify reproducing the issue.
Using the latest stable verison of Docker is always recommended. Support for older version is on a best-effort basis.

# Building the container yourself
To build this container, clone the repository and cd into it.

## Build it:
```
$ cd /repo/location/jackettvpn
$ docker build -t jackettvpn .
```
## Run it:
```
$ docker run --privileged  -d \
              -v /your/config/path/:/config \
              -v /your/blackhole/path/:/blackhole \
              -e "VPN_ENABLED=yes" \
              -e "LAN_NETWORK=192.168.0.0/24" \
              -e "NAME_SERVERS=1.1.1.1,1.0.0.1" \
              -p 9117:9117 \
              --restart unless-stopped \
              dyonr/jackettvpn
```
