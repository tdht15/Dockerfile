# This Dockerfile is used to build an headles vnc image based on Ubuntu

FROM ubuntu:latest

MAINTAINER Chris Ruettimann "chris@bitbull.ch"
ENV REFRESHED_AT 2023-05-17-10:44
ENV VERSION 1.7.59

LABEL io.k8s.description="Headless VNC Container with Xfce window manager" \
      io.k8s.display-name="Headless VNC Container based on Ubuntu" \
      io.openshift.expose-services="6901:http,5901:xvnc" \
      io.openshift.tags="vnc, ubuntu, xfce" \
      io.openshift.non-scalable=true

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901
EXPOSE $VNC_PORT $NO_VNC_PORT

USER root
### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false \
    LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'

WORKDIR $HOME

RUN apt-get update

RUN apt-get install -y apt-utils locales language-pack-en language-pack-en-base ; update-locale 

RUN add-apt-repository ppa:mozillateam/ppa ; echo -n 'Package: * \nPin: release o=LP-PPA-mozillateam \nPin-Priority: 1001 \n' > /etc/apt/preferences.d/mozilla-firefox ; echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' > /etc/apt/apt.conf.d/51unattended-upgrades-firefox 

RUN apt-get install -y \
    geany geany-plugins-common \
    firefox \
    imagemagick \
    libreoffice \
    libnss-wrapper \
    ttf-wqy-zenhei \
    gettext \
    pinta \
    software-properties-common \
    xfce4 \
    xfce4-terminal \
    xterm \
    evince 

RUN apt-get install -y \
    ansible \
    git \
    unzip \
    xz-utils \
    openssh-client \
    openssl \
    dnsutils \
    curl \
    screen \
    smbclient \
    wget \
    rsync \
    whois \
    netcat \
    nmap \
    terminator \
    tmux \
    vim \
    wget \
    net-tools \
    locales \
    bzip2 \
    python3-numpy \
    supervisor \
    xdotool \
    xautomation

RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    rm -f packages.microsoft.gpg && \
    apt-get -y install apt-transport-https && \
    apt-get update && \
    apt-get -y install code

### noVNC needs python2 and ubuntu docker image is not providing any default python
RUN test -e /usr/bin/python && rm -f /usr/bin/python ; ln -s /usr/bin/python3 /usr/bin/python

RUN apt-get purge -y pm-utils xscreensaver* && \
    apt-get -y clean

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN mkdir -p $NO_VNC_HOME/utils/websockify && \
    wget -qO- https://netcologne.dl.sourceforge.net/project/tigervnc/stable/1.10.1/tigervnc-1.10.1.x86_64.tar.gz | tar xz --strip 1 -C / && \
    wget -qO- https://github.com/novnc/noVNC/archive/v1.2.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME && \
    wget -qO- https://github.com/novnc/websockify/archive/v0.10.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify && \
    chmod +x -v $NO_VNC_HOME/utils/*.sh && \
    cp -f /headless/noVNC/vnc.html /headless/noVNC/index.html

### inject files
ADD ./src/xfce/ $HOME/
ADD ./src/scripts $STARTUPDIR

ADD ./src/etc /
RUN add-apt-repository ppa:mozillateam/ppa

### configure startup and set perms
RUN echo "CHROMIUM_FLAGS='--no-sandbox --start-maximized --user-data-dir'" > $HOME/.chromium-browser.init && \
    /bin/sed -i '1 a. /headless/.bashrc' /etc/xdg/xfce4/xinitrc && \
    find $STARTUPDIR $HOME -name '*.sh' -exec chmod a+x {} + && \
    find $STARTUPDIR $HOME -name '*.desktop' -exec chmod a+x {} + && \
    chgrp -R 0 $STARTUPDIR $HOME && \
    chmod -R a+rw $STARTUPDIR $HOME && \
    find $STARTUPDIR $HOME -type d -exec chmod a+x {} + && \
    echo LANG=en_US.UTF-8 > /etc/default/locale && \
    locale-gen en_US.UTF-8

USER 1000

ENTRYPOINT ["/dockerstartup/desktop_startup.sh"]
CMD ["--wait"]
