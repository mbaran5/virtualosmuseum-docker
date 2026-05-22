#!/bin/bash
set -e

# No DISPLAY needed - QEMU serves VNC directly, no Xvfb/SDL involved

# Locate disks and hostfs
HOST_DISK=$(find /vm -maxdepth 4 -name "host_x86.vdi" | head -1)
GUEST_DISK=$(find /vm -maxdepth 4 -name "guest_images.vdi" | head -1)
HOSTFS=$(find /vm -maxdepth 3 -type d -name "hostfs" | head -1)

[ -z "$HOST_DISK"  ] && { echo "ERROR: host_x86.vdi not found";    find /vm -maxdepth 4; exit 1; }
[ -z "$GUEST_DISK" ] && { echo "ERROR: guest_images.vdi not found"; find /vm -maxdepth 4; exit 1; }
[ -z "$HOSTFS" ]     && { HOSTFS="$(dirname "$(dirname "$HOST_DISK")")/hostfs"; mkdir -p "$HOSTFS"; }

echo "Host disk:  $HOST_DISK"
echo "Guest disk: $GUEST_DISK"
echo "Host FS:    $HOSTFS"

RAM=${QEMU_RAM:-8192}
CPUS=${QEMU_CPUS:-4}

echo "Starting QEMU with ${RAM}MB RAM, ${CPUS} vCPUs..."

# QEMU serves VNC directly on :1 (port 5901)
# noVNC websockify proxies 5901 -> browser on 8080
# No Xvfb, no x11vnc, no SDL window positioning issues
exec qemu-system-x86_64 \
    -enable-kvm \
    -m "${RAM}" \
    -smp "${CPUS}" \
    -display vnc=127.0.0.1:1 \
    -vga std \
    -M pc,vmport=off \
    -device ahci,id=ahci \
    -drive id=disk0,file="${HOST_DISK}",if=none,discard=unmap \
    -device ide-hd,drive=disk0,bus=ahci.0 \
    -drive id=disk1,file="${GUEST_DISK}",if=none,discard=unmap \
    -device ide-hd,drive=disk1,bus=ahci.1 \
    -device e1000,netdev=eth0 \
    -netdev user,id=eth0,hostfwd=tcp::8022-:22,hostfwd=tcp::4711-:4711 \
    -audio model=hda,driver=none \
    -virtfs local,path="${HOSTFS}",mount_tag=hostfs,security_model=mapped \
    -boot c
