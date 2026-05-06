# AIC8800D80 WiFi Driver Fix for Linux Kernel 6.17

## Problem
USB WiFi adapters with AIC8800D80 chipset (shown as `1111:1111 Pandora International Ltd. 88M80` in `lsusb`) fail to work on kernel 6.17 due to API changes.

## Symptoms
- `lsusb` shows `ID 1111:1111 Pandora International Ltd. 88M80`
- No `wlan` interface appears in `ip link show`
- Driver fails to compile with DKMS errors

## Affected devices
- WIFI6-BW22 / BW23
- AX900 WiFi 6 USB Adapter
- 88M80 / AIC8800D80 / AIC8800M80
- Any unbranded "900Mbps WiFi 6 USB Adapter" showing `1111:1111` in lsusb

## Quick Install (recommended)

```bash
git clone https://github.com/Williankfa/AIC8800D80-kernel-6.17-fix.git
cd AIC8800D80-kernel-6.17-fix
sudo bash install.sh
```

Then reboot your PC.

## Tested on
- Zorin OS 17 with kernel 6.17.0-23-generic
- Adapter: `1111:1111 Pandora International Ltd. 88M80` (AIC8800D80)

## Bugs fixed in kernel 6.17
- `from_timer` removed → replaced with `timer_container_of`
- `cfg80211_rx_spurious_frame` requires extra argument
- `cfg80211_rx_unexpected_4addr_frame` requires extra argument
- `set_tx_power` signature changed
- `set_wiphy_params` gained `radio_idx` argument

## Credits
- Base driver: [radxa-pkg/aic8800](https://github.com/radxa-pkg/aic8800)
- Modeswitch: [olamellberg/AIC8800D80](https://github.com/olamellberg/AIC8800D80)
