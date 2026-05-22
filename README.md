# virtualosmuseum-docker

Run the [Virtual OS Museum](https://virtualosmuseum.org) in a browser via Docker, with full audio, mouse capture, and pointer lock support.

The Virtual OS Museum is a curated collection of 1,700+ pre-installed operating systems spanning the entire history of computing, from 1948 to the present day. This repo packages it as a Docker Compose stack with browser-based access via noVNC — no VirtualBox, no local QEMU install, no display server required.

## How it works

QEMU/KVM runs the museum's host Linux VM with its built-in VNC server. noVNC (happylabdab2 fork with pointer lock) proxies that to your browser over WebSocket. Audio is captured from PulseAudio inside the museum VM and streamed as WebM/Opus via GStreamer.

```
QEMU/KVM (museum VM)
  ├── VNC :5901 → websockify → browser (video + input)
  └── PulseAudio :4711 → GStreamer audio-proxy :5711 → websockify → browser (audio)
```

Mouse input uses PS/2 relative mode (no USB tablet), which is required for correct mouse behavior inside the old OS emulators (QEMU 0.8.x, MAME, VICE) that the museum runs. This matches the upstream VirtualBox configuration.

## Requirements

- Docker with Compose
- A CPU with KVM virtualization support (`/dev/kvm` must exist)
- Nested virtualization recommended for best guest OS performance:
  - AMD: `cat /sys/module/kvm_amd/parameters/nested` should return `1`
  - Intel: `cat /sys/module/kvm_intel/parameters/nested` should return `Y`
- ~25GB free disk space for the lite edition

## Setup

**1. Clone this repo**

```bash
git clone https://github.com/mbaran5/virtualosmuseum-docker
cd virtualosmuseum-docker
```

**2. Download the Virtual OS Museum VM**

```bash
chmod +x setup-vm.sh
./setup-vm.sh /your/storage/path
```

This downloads the lite edition (~14GB) from Internet Archive and extracts it. The download is resumable if interrupted. The lite edition downloads individual guest OS disk images on first run — an internet connection is required the first time you launch each OS.

If you prefer the full offline edition (~121GB zipped), download it manually from [virtualosmuseum.org/downloads](https://virtualosmuseum.org/downloads) and extract it to the same path.

**3. Update the volume path in `compose.yaml`**

```yaml
volumes:
  - /your/storage/path:/vm
```

**4. Build and start**

```bash
docker compose up -d --build
```

**5. Open in your browser**

```
http://your-host:8888/vnc.html?path=websockify%3Ftoken%3Dvnc
```

The museum launcher will appear. Double-click any OS to run it.

**6. Enable audio**

In the noVNC sidebar, scroll to the bottom and expand **Audio Plugin**. Check **Enabled** and click anywhere on the desktop to start playback.

## Mouse

Mouse behavior matches the upstream VirtualBox experience — the cursor is not integrated and must be captured:

- **Click** anywhere on the canvas to capture the mouse (pointer lock)
- **Escape** to release
- **Fullscreen mode** has an additional pointer lock button in the noVNC toolbar

This is required for correct mouse tracking inside old OS emulators. The XFCE desktop and all modern emulators work with standard absolute mouse. Old emulators (pre-2000 PC OSes, classic Mac OS via MAME, Commodore via VICE) require the captured PS/2 relative mouse to work correctly.

## Configuration

All tunables are environment variables in `compose.yaml`:

| Variable | Default | Description |
|---|---|---|
| `QEMU_RAM` | `8192` | RAM for the museum VM in MB |
| `QEMU_CPUS` | `4` | vCPUs for the museum VM |

## Ports

| Port | Description |
|---|---|
| `8888` | noVNC browser UI |
| `8022` | SSH into the museum VM (username: `osmuseum`, password: `osmuseum`) |

## Troubleshooting

**Container starts but browser shows nothing**
Check QEMU logs: `docker logs virtualosmuseum`

**KVM not available**
Ensure `/dev/kvm` exists and is accessible: `ls -la /dev/kvm`

**Guest OSes run slowly**
Nested virtualization may not be enabled. To enable on AMD (persistent):
```bash
echo "options kvm_amd nested=1" | sudo tee /etc/modprobe.d/kvm-amd.conf
```

**Mouse is captured but cursor is offset inside old PC guests**
This is expected — the PS/2 relative mouse requires the cursor to be captured before entering a guest window. Click the canvas to capture first, then click into the emulator window.

**No audio**
Enable the Audio Plugin in the noVNC sidebar settings panel. Audio requires a click on the page to start due to browser autoplay policies.

**SSH into the museum VM**
```bash
ssh -p 8022 osmuseum@your-host   # password: osmuseum
```

## Notes

- This repo contains only the Docker wrapper. The Virtual OS Museum VM files are not included and must be downloaded separately per the above instructions.
- The museum VM and its contents are the work of [Andrew Warkentin](https://virtualosmuseum.org/about-the-curator). Please consider supporting the project on [Patreon](https://www.patreon.com/andreww591) or [Ko-fi](https://ko-fi.com/andreww591).
- Commercial OS images included in the museum are for historical research and preservation purposes only.

## License

The Docker wrapper files in this repo (Dockerfile, compose.yaml, start-qemu.sh, supervisord.conf, setup-vm.sh, setup-audio.sh) are MIT licensed. The Virtual OS Museum itself is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
