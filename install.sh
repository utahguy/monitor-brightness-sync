#!/usr/bin/env bash
set -euo pipefail

echo "=== monitor-brightness-sync installer ==="

# 1. Install system dependencies
echo "Installing ddcutil and inotify-tools..."
sudo apt install -y ddcutil inotify-tools

# 2. Load the i2c-dev kernel module (required for ddcutil)
if ! lsmod | grep -q i2c_dev; then
    echo "Loading i2c-dev kernel module..."
    sudo modprobe i2c-dev
fi
# Make it persistent across reboots
if ! grep -qs '^i2c-dev' /etc/modules-load.d/*.conf 2>/dev/null; then
    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
    echo "Added i2c-dev to load at boot"
fi

# 3. Add current user to i2c group (required for non-root ddcutil)
if ! groups | grep -q '\bi2c\b'; then
    echo "Adding $USER to the i2c group..."
    sudo usermod -aG i2c "$USER"
    echo "NOTE: Log out and back in (or reboot) for group membership to take effect."
fi

# 4. Install the script
mkdir -p ~/.local/bin
cp monitor-brightness-sync ~/.local/bin/
chmod +x ~/.local/bin/monitor-brightness-sync
echo "Installed script to ~/.local/bin/monitor-brightness-sync"

# 5. Install the systemd user service
mkdir -p ~/.config/systemd/user
cp monitor-brightness-sync.service ~/.config/systemd/user/
systemctl --user daemon-reload
echo "Installed systemd user service"

echo ""
echo "=== Installation complete ==="
echo ""
echo "Quick test (one-shot, dry run):"
echo "  monitor-brightness-sync --once --dry-run"
echo ""
echo "Start the service:"
echo "  systemctl --user enable --now monitor-brightness-sync"
echo ""
echo "Check status:"
echo "  systemctl --user status monitor-brightness-sync"
echo ""
echo "View logs:"
echo "  journalctl --user -u monitor-brightness-sync -f"
