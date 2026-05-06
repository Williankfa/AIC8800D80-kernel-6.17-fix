# AIC8800D80 WiFi Driver Fix for Linux Kernel 6.17

## Problema
Adaptadores WiFi USB com chipset AIC8800D80 (que aparecem como `1111:1111 Pandora International Ltd. 88M80` no `lsusb`) não funcionam no kernel 6.17 por incompatibilidades de API.

## Sintomas
- `lsusb` mostra `ID 1111:1111 Pandora International Ltd. 88M80`
- Nenhuma interface `wlan` aparece no `ip link show`
- Driver falha ao compilar com erros no `dkms`

## Solução

### 1. Instalar dependências
```bash
sudo apt install git dkms linux-headers-$(uname -r) build-essential usb-modeswitch -y
```

### 2. Baixar o pacote do driver
```bash
cd ~
wget https://github.com/radxa-pkg/aic8800/releases/download/3.0%2Bgit20240327.3561b08f-6/aic8800-firmware_3.0+git20240327.3561b08f-6_all.deb
wget https://github.com/radxa-pkg/aic8800/releases/download/3.0%2Bgit20240327.3561b08f-6/aic8800-usb-dkms_3.0+git20240327.3561b08f-6_all.deb
sudo dpkg -i aic8800-firmware_*.deb aic8800-usb-dkms_*.deb
```

### 3. Aplicar correções para o kernel 6.17

```bash
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
```

### 4. Compilar e instalar o driver
```bash
sudo dkms build aic8800-usb/3.0+git20240327.3561b08f-6 -k $(uname -r) --force
sudo dkms install aic8800-usb/3.0+git20240327.3561b08f-6 -k $(uname -r) --force
```

### 5. Configurar modeswitch automático
```bash
git clone https://github.com/olamellberg/AIC8800D80.git
sudo cp ~/AIC8800D80/linux/usb_modeswitch/1111_1111 /etc/usb_modeswitch.d/1111:1111
sudo udevadm control --reload-rules
sudo modprobe aic8800_fdrv_usb
sudo modprobe aic_load_fw_usb
```

### 6. Reiniciar
```bash
sudo reboot
```

Após reiniciar, o adaptador deve aparecer como `wlx...` no `ip link show`.

## Erros corrigidos
- `from_timer` removido no kernel 6.17 → substituído por `timer_container_of`
- `cfg80211_rx_spurious_frame` ganhou argumento extra
- `cfg80211_rx_unexpected_4addr_frame` ganhou argumento extra  
- `set_tx_power` mudou assinatura
- `set_wiphy_params` ganhou argumento `radio_idx`

## Testado em
- Zorin OS 17 com kernel 6.17.0-23-generic
- Adaptador: `1111:1111 Pandora International Ltd. 88M80` (AIC8800D80)

## Créditos
- Driver base: [radxa-pkg/aic8800](https://github.com/radxa-pkg/aic8800)
- Modeswitch: [olamellberg/AIC8800D80](https://github.com/olamellberg/AIC8800D80)
