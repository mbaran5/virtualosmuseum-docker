#!/bin/bash
for i in $(seq 1 60); do
    sshpass -p osmuseum ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p 8022 osmuseum@127.0.0.1 true 2>/dev/null && break
    sleep 5
done

# Get the monitor source index dynamically
MONITOR_SOURCE=$(sshpass -p osmuseum ssh -o StrictHostKeyChecking=no -p 8022 osmuseum@127.0.0.1 \
    "pactl list sources short | grep monitor | head -1 | cut -f1")

sshpass -p osmuseum ssh -o StrictHostKeyChecking=no -p 8022 osmuseum@127.0.0.1 \
    "pactl load-module module-simple-protocol-tcp listen=0.0.0.0 port=4711 format=s16le channels=2 rate=48000 record=true playback=false source=${MONITOR_SOURCE}"

echo "Audio module loaded on source ${MONITOR_SOURCE}"
