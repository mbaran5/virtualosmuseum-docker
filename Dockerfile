FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    qemu-system-x86 \
    qemu-utils \
    qemu-system-gui \
    novnc \
    websockify \
    supervisor \
    wget \
    unzip \
    curl \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Serve vnc.html as the index for convenience
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

RUN mkdir -p /vm /run/supervisor
VOLUME ["/vm"]

COPY supervisord.conf /etc/supervisor/conf.d/virtualosmuseum.conf
COPY start-qemu.sh /usr/local/bin/start-qemu.sh
RUN chmod +x /usr/local/bin/start-qemu.sh

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
