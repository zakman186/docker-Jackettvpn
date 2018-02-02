# Transmission and OpenVPN
#
# Version 1.5

FROM ubuntu:16.04
MAINTAINER MarkusMcNugen

VOLUME /data
VOLUME /config

# Update packages and install software
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && add-apt-repository ppa:qbittorrent-team/qbittorrent-stable \
    && apt-get update \
    && apt-get install -y qbittorrent-nox openvpn curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
#    && curl -L https://github.com/jwilder/dockerize/releases/download/v0.0.2/dockerize-linux-amd64-v0.0.2.tar.gz | tar -C /usr/local/bin -xzv

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD qBittorrent/ /etc/qBittorrent/

ENV OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** 

# Expose port and run
EXPOSE 8080
CMD ["/etc/openvpn/start.sh"]
CMD ["/usr/bin/qbittorrent-nox -d"]
