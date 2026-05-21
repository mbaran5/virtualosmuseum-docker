#!/bin/bash
# Downloads and extracts the Virtual OS Museum lite edition from Internet Archive.
# Run this once on the host before starting the container.
#
# Usage: ./setup-vm.sh [destination]
# Default destination: ./vm-data

set -e

DEST="${1:-./vm-data}"
URL="https://archive.org/download/virtual_os_museum_lite_edition/virtual_os_museum-2026.05.19-lite.zip"
ZIPFILE="${DEST}/virtual_os_museum-lite.zip"

echo "==> Destination: ${DEST}"
mkdir -p "$DEST"

echo "==> Downloading Virtual OS Museum lite edition (~14GB)..."
echo "    This will take a while. The download is resumable if interrupted."
wget -c -O "$ZIPFILE" "$URL"

echo "==> Extracting..."
unzip -o "$ZIPFILE" -d "$DEST"

echo "==> Cleaning up zip..."
rm -f "$ZIPFILE"

echo ""
echo "Done! VDI images found:"
find "$DEST" -maxdepth 4 \( -name "*.vdi" \)
echo ""
echo "Update the volume path in compose.yaml to point to: ${DEST}"
echo "Then start with: docker compose up -d --build"
