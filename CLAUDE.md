# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`monitor-brightness-sync` is a pure-bash daemon that watches the laptop's kernel backlight (`/sys/class/backlight/*/brightness`) via `inotifywait` and mirrors brightness changes to external monitors using `ddcutil` (DDC/CI over I2C). It runs as a systemd user service.

## Repository Structure

- `monitor-brightness-sync` — the main bash script (daemon + one-shot + calibrate modes)
- `monitor-brightness-sync.service` — systemd user unit file
- `install.sh` — installer (apt deps, i2c-dev module, i2c group, script + service install)
- `~/.config/monitor-brightness-sync/monitors.conf` — per-monitor VCP calibration (created by `--calibrate`)

## Key Commands

```sh
# Install (requires sudo for apt, modprobe, usermod)
./install.sh

# Calibrate new monitors (interactive)
monitor-brightness-sync --calibrate

# Test without modifying monitors
monitor-brightness-sync --once --dry-run

# One-shot sync
monitor-brightness-sync --once

# Service management
systemctl --user enable --now monitor-brightness-sync
journalctl --user -u monitor-brightness-sync -f
```

There is no build step, test suite, or linter configured.

## Architecture Notes

- The script uses `inotifywait -m` to watch for kernel writes to the backlight `brightness` sysfs file, coalescing rapid key-hold events with a short sleep + drain loop.
- Monitor detection (`ddcutil detect --terse`) results are cached for `MONITOR_CACHE_TTL` seconds to handle hotplug without restarting. Each monitor is identified by its `manufacturer:model:serial` string from ddcutil.
- Each candidate monitor bus is verified with both a getvcp read and setvcp write before being added to the active list.
- Per-monitor VCP calibration is stored in `~/.config/monitor-brightness-sync/monitors.conf`. Laptop 0–100% is scaled linearly to each monitor's calibrated VCP range. Uncalibrated monitors default to 0–100.
- `--calibrate` uses interactive binary search to find the VCP value where the monitor's OSD reads 100.
- DDC/CI calls include a single retry with 200ms backoff for flaky I2C buses, plus 100ms inter-monitor pauses to avoid bus contention.
- `DDCUTIL` path is hardcoded at the top of the script as a security measure against command injection via `$PATH` manipulation.

## Security Considerations

- The `ddcutil` path variable exists to prevent command injection — do not change it to use user-supplied or environment-derived paths.
- Bus numbers used in `ddcutil` calls come from `ddcutil detect` output parsed via regex, not from user input.
