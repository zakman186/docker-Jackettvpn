# Jackett and OpenVPN
#
# Version Development

FROM ubuntu:18.04
MAINTAINER DyonR

ENV DEBIAN_FRONTEND noninteractive
ENV XDG_DATA_HOME="/config" \
XDG_CONFIG_HOME="/config"

WORKDIR /opt

RUN usermod -u 99 nobody

#make directories
RUN mkdir -p /blackhole /config/Jackett /etc/jackett

# Update packages and install software
RUN apt update \
    && apt -y install \
    apt-transport-https \
    wget \
    curl \
    gnupg \
    sed \
    openvpn \
    curl \
    moreutils \
    net-tools \
    dos2unix \
    kmod \
    iptables \
    ipcalc\
    grep \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" >> /etc/apt/sources.list.d/mono-official-stable.list \
    && apt update \
    && apt -y install \
    ca-certificates-mono \
    libcurl4-openssl-dev \
    mono-devel 

#Install jackett
RUN jackett_latest=$(curl --silent "https://api.github.com/repos/Jackett/Jackett/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -o /opt/Jackett.Binaries.Mono.tar.gz -L https://github.com/Jackett/Jackett/releases/download/$jackett_latest/Jackett.Binaries.Mono.tar.gz \
    && tar -xvzf /opt/Jackett.Binaries.Mono.tar.gz \
    && rm /opt/Jackett.Binaries.Mono.tar.gz

VOLUME /blackhole /config

ADD openvpn/ /etc/openvpn/
ADD jackett/ /etc/jackett/

RUN chmod +x /etc/jackett/*.sh /etc/jackett/*.init /etc/openvpn/*.sh

EXPOSE 9117
CMD ["/bin/bash", "/etc/openvpn/start.sh"]