FROM ubuntu

ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y iptables tcpdump dsniff iproute2 python3 python3-pip tmux dnsutils pipx

# Use pipx for globally accessible python applications
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIPX_HOME=/opt/pipx
RUN pipx ensurepath
RUN pipx install mitmproxy

CMD ["/bin/bash", "-c", "trap : TERM INT; sleep infinity & wait"]