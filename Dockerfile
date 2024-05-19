FROM debian
RUN dpkg --add-architecture i386
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install wine qemu-kvm *zenhei* xz-utils dbus-x11 curl firefox-esr gnome-system-monitor mate-system-monitor  git xfce4 xfce4-terminal tightvncserver wget   -y
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.2.0.tar.gz
RUN tar -xvf v1.2.0.tar.gz
RUN mkdir  $HOME/.vnc
RUN echo 't' | vncpasswd -f > $HOME/.vnc/passwd
RUN echo '/bin/env  MOZ_FAKE_NO_SANDBOX=1  dbus-launch xfce4-session'  > $HOME/.vnc/xstartup
RUN chmod 600 $HOME/.vnc/passwd
RUN chmod 755 $HOME/.vnc/xstartup
RUN echo 'whoami ' >>/tu.sh
RUN echo 'cd ' >>/tu.sh
RUN echo "su -l -c 'vncserver :2000 -geometry 1360x768' "  >>/tu.sh
RUN echo 'cd /noVNC-1.2.0' >>/tu.sh
RUN echo './utils/launch.sh  --vnc localhost:7900 --listen 8900 ' >>/tu.sh
RUN chmod 755 /tu.sh
EXPOSE 8900
CMD  /tu.sh 
