FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    # QEMU/KVM
    qemu-system-x86 \
    qemu-utils \
    qemu-system-gui \
    # websockify
    websockify \
    # Process supervisor
    supervisor \
    # Audio
    pulseaudio \
    # Audio plugin dependencies
    socat \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    # Utilities
    wget \
    curl \
    net-tools \
    git \
    python3 \
    python3-pip \
    && pip3 install evdev websockets --break-system-packages \
    && rm -rf /var/lib/apt/lists/*

# noVNC (happylabdab2 fork with pointer lock)
RUN git clone --depth 1 https://github.com/happylabdab2/noVNC.git /usr/share/novnc \
    && chmod +x /usr/share/novnc/utils/novnc_proxy

# Audio plugin
RUN git clone --depth 1 https://github.com/me-asri/noVNC-audio-plugin.git /tmp/audio-plugin \
    && cp /tmp/audio-plugin/audio-plugin.js /usr/share/novnc/audio-plugin.js \
    && cp /tmp/audio-plugin/audio-proxy.sh /usr/local/bin/audio-proxy.sh \
    && chmod +x /usr/local/bin/audio-proxy.sh \
    && rm -rf /tmp/audio-plugin

# Patch vnc.html to load audio plugin
RUN sed -i 's|</head>|<script type="module" crossorigin="anonymous" src="audio-plugin.js"></script></head>|' /usr/share/novnc/vnc.html

# Patch vnc.html to add windowed mouse lock and suppress scroll during lock
RUN printf '<script>\nwindow.addEventListener("load", function() {\n    setTimeout(function() {\n        var c = document.querySelector("canvas");\n        if (c) {\n            c.addEventListener("mousedown", function() {\n                c.requestPointerLock();\n            });\n            document.addEventListener("wheel", function(e) {\n                if (document.pointerLockElement === c) {\n                    e.stopImmediatePropagation();\n                }\n            }, true);\n        }\n    }, 3000);\n});\n</script>\n' >> /usr/share/novnc/vnc.html

# Websockify token config
RUN mkdir -p /etc/websockify && printf "vnc: 127.0.0.1:5901\naudio: 127.0.0.1:5711\n" > /etc/websockify/token.cfg

# PulseAudio config
RUN mkdir -p /tmp/pulse
COPY pulse-default.pa /etc/pulse/default.pa

# Patch audio-proxy to use PulseAudio directly instead of TCP
RUN sed -i 's|tcpclientsrc port="${pulse_port}" ! rawaudioparse use-sink-caps=false format=pcm pcm-format="${pulse_format}" sample-rate="${pulse_sample_rate}" num-channels="${pulse_channels}"|pulsesrc server=unix:/tmp/pulse/native device=qemu_output.monitor|' /usr/local/bin/audio-proxy.sh

RUN mkdir -p /vm /run/supervisor
VOLUME ["/vm"]
COPY supervisord.conf /etc/supervisor/conf.d/virtualosmuseum.conf
COPY start-qemu.sh /usr/local/bin/start-qemu.sh
RUN chmod +x /usr/local/bin/start-qemu.sh
EXPOSE 8080
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
