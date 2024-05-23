# ubuntu:18.04 tightvncserver novnc
FROM ubuntu:18.04 as heungBuntu

## Connection ports for controlling the UI:
# VNC port:5900
# noVNC webport, connect via http://IP:6900/?password=vncpassword
ENV DISPLAY=:0 \
    VNC_PORT=5900 \
    NO_VNC_PORT=6900

### Envrionment config
ENV HOME=/home \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1920x1080 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false \
    VNC_DIR=/noVNC \
    DEBIAN_FRONTEND=noninteractive
	
WORKDIR $HOME

# local, Timezone 
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo -e "\nLANG=\"ko_KR.UTF-8\"\nLANGUAGE=\"ko:en\"\nLC_ALL=\"C.UTF-8\"" > /etc/default/locale

# Install some common tools
RUN apt update -y \
    && apt install -y --no-install-recommends apt-utils \
    && apt install -y vim build-essential curl wget net-tools locales python-numpy git-core fonts-nanum* fcitx fcitx-hangul language-selector-common  \
    && apt install -y `check-language-support -l ko`  \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

#SHELL ["/bin/bash", "-c"]

# Install xwindow
RUN apt update -y \
    && apt install -y xfce4 xfce4-goodies xubuntu-desktop \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install tightVNC
RUN apt update -y \
    && apt install -y tightvncserver \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# vncpassword 
RUN mkdir /root/.vnc
RUN echo $VNC_PW | vncpasswd -f > /root/.vnc/passwd \
    && chmod 600 /root/.vnc/passwd

RUN echo "#!/bin/sh\nxrdb $HOME/.Xresources\nxsetroot -solid grey\nx-terminal-emulator -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &\nstartxfce4 &" > /root/.vnc/xstartup \
    && chmod +x  /root/.vnc/xstartup

RUN git clone https://github.com/novnc/noVNC.git $VNC_DIR
RUN echo "rm -rf /tmp/.X0-lock /tmp/.X11-unix\nsu -c \"vncserver $DISPLAY -geometry $VNC_RESOLUTION\" \n/$VNC_DIR/utils/launch.sh --listen $NO_VNC_PORT --vnc localhost:$VNC_PORT --web $VNC_DIR" > $VNC_DIR/start_vnc.sh \
    && chmod +x $VNC_DIR/start_vnc.sh

EXPOSE $VNC_PORT $NO_VNC_PORT

ENTRYPOINT  ["/bin/bash", "/noVNC/start_vnc.sh"]
