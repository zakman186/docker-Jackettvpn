# qBittorrent and OpenVPN
#
# Version 1.0

FROM ubuntu:16.04
MAINTAINER MarkusMcNugen

VOLUME /downloads
VOLUME /config

ENV DEBIAN_FRONTEND noninteractive

RUN groupadd -g 100 users
RUN useradd -s /bin/bash -u 99 -g 100 nobody

# Update packages and install software
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && add-apt-repository ppa:qbittorrent-team/qbittorrent-stable \
    && apt-get update \
    && apt-get install -y qbittorrent-nox openvpn curl moreutils net-tools dos2unix kmod iptables ipcalc \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/

RUN chmod +x /etc/qbittorrent/*.sh /etc/openvpn/*.sh

# Expose ports and run
EXPOSE 8080
EXPOSE 8999
EXPOSE 8999/udp
CMD ["/bin/bash", "/etc/openvpn/start.sh"]
