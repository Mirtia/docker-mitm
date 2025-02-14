FROM ubuntu

ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y iptables tcpdump dsniff iproute2 python3 python3-pip tmux dnsutils
RUN apt install -y python3-virtualenv build-essential libssl-dev libffi-dev \
    && virtualenv --python=python3 pyenv \
    && . pyenv/bin/activate \
    && pip3 install --upgrade pip \
    && pip3 install scapy mitmproxy

CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
