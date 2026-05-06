#!/bin/bash
set -e

echo "========================================"
echo " AIC8800D80 WiFi Driver Installer"
echo " Kernel 6.17 compatible"
echo "========================================"

echo "[1/6] Installing dependencies..."
sudo apt install -y git dkms linux-headers-$(uname -r) build-essential usb-modeswitch wget

echo "[2/6] Downloading driver..."
cd /tmp
wget -q https://github.com/radxa-pkg/aic8800/releases/download/3.0%2Bgit20240327.3561b08f-6/aic8800-firmware_3.0+git20240327.3561b08f-6_all.deb
wget -q https://github.com/radxa-pkg/aic8800/releases/download/3.0%2Bgit20240327.3561b08f-6/aic8800-usb-dkms_3.0+git20240327.3561b08f-6_all.deb
sudo dpkg -i aic8800-firmware_*.deb aic8800-usb-dkms_*.deb || true

echo "[3/6] Applying fixes for kernel 6.17..."
BASE="/usr/src/aic8800-usb-3.0+git20240327.3561b08f-6/USB/driver_fw/drivers/aic8800/aic8800_fdrv"

sudo sed -i 's/from_timer(preorder_ctrl, t, reord_timer)/timer_container_of(preorder_ctrl, t, reord_timer)/' $BASE/rwnx_rx.c
sudo sed -i 's/cfg80211_rx_spurious_frame(rwnx_vif->ndev, hdr->addr2, GFP_ATOMIC)/cfg80211_rx_spurious_frame(rwnx_vif->ndev, hdr->addr2, 0, GFP_ATOMIC)/' $BASE/rwnx_rx.c
sudo python3 -c "
f = '$BASE/rwnx_rx.c'
content = open(f).read()
old = 'cfg80211_rx_unexpected_4addr_frame(rwnx_vif->ndev,\n                                                       sta->mac_addr, GFP_ATOMIC);'
new = 'cfg80211_rx_unexpected_4addr_frame(rwnx_vif->ndev, sta->mac_addr, 0, GFP_ATOMIC);'
content = content.replace(old, new)
open(f, 'w').write(content)
"
sudo sed -i 's/from_timer(rwnx_hw, t, p2p_alive_timer)/timer_container_of(rwnx_hw, t, p2p_alive_timer)/' $BASE/rwnx_main.c
sudo python3 -c "
f = '$BASE/rwnx_main.c'
content = open(f).read()
old = 'static int rwnx_cfg80211_set_tx_power(struct wiphy *wiphy, int idx,\n#if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0)\n struct wireless_dev *wdev,\n#endif\n                                      enum nl80211_tx_power_setting type, int mbm)'
new = 'static int rwnx_cfg80211_set_tx_power(struct wiphy *wiphy, struct wireless_dev *wdev, int idx, enum nl80211_tx_power_setting type, int mbm)'
content = content.replace(old, new)
open(f, 'w').write(content)
"
sudo sed -i 's/static int rwnx_cfg80211_set_wiphy_params(struct wiphy \*wiphy, u32 changed)/static int rwnx_cfg80211_set_wiphy_params(struct wiphy *wiphy, int radio_idx, u32 changed)/' $BASE/rwnx_main.c

echo "[4/6] Building and installing driver..."
sudo dkms build aic8800-usb/3.0+git20240327.3561b08f-6 -k $(uname -r) --force
sudo dkms install aic8800-usb/3.0+git20240327.3561b08f-6 -k $(uname -r) --force

echo "[5/6] Setting up automatic modeswitch..."
cd /tmp
git clone -q https://github.com/olamellberg/AIC8800D80.git
sudo cp /tmp/AIC8800D80/linux/usb_modeswitch/1111_1111 /etc/usb_modeswitch.d/1111:1111
sudo udevadm control --reload-rules

echo "[6/6] Loading modules..."
sudo modprobe aic8800_fdrv_usb || true
sudo modprobe aic_load_fw_usb || true

echo ""
echo "========================================"
echo " Installation complete!"
echo " Please reboot your PC."
echo "========================================"
