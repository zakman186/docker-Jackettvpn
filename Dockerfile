# Transmission and OpenVPN
#
# Version 1.5

FROM ubuntu:16.04
MAINTAINER MarkusMcNugen

VOLUME /downloads
VOLUME /config

# Update packages and install software
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && apt-get install -y qbittorrent-nox openvpn curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/

ENV OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** 

# Expose ports and run
EXPOSE 8080
EXPOSE 8999
EXPOSE 8999/udp
CMD ["/etc/openvpn/start.sh"]
CMD ["/etc/qbittorrent/start.sh"]
