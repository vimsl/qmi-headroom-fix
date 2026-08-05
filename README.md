# qmi-headroom-fix

Kprobe-based kernel module to fix QMI WWAN skb headroom issues on MediaTek MT798x 5G CPE platforms.

## Problem

The `qmi_wwan_f` driver's `usbnet_start_xmit()` may trigger skb headroom/tailroom warnings when the 5G modem (e.g. Fibocom FM170-EAU) sends packets requiring additional `LL_MAX_HEADER` space (176 bytes).

## Solution

Uses Linux kprobes to intercept `usbnet_start_xmit()` and ensures sufficient skb headroom before transmission, preventing kernel warnings and potential packet drops.

## CI Build

GitHub Actions automatically:
1. Downloads Linux kernel 6.6.148 source
2. Cross-compiles `qmi_fix_skb.ko` for ARM64
3. Creates a GitHub release with the module

## Manual Build

```bash
sudo apt install gcc-aarch64-linux-gnu make libelf-dev
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.148.tar.xz
tar -xf linux-6.6.148.tar.xz && cd linux-6.6.148
cp ../config-6.6.148.txt .config
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_prepare
KBUILD_MODPOST_WARN=1 make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -C . M=$PWD/.. modules
```

## Files

- `qmi_fix_skb.c` — Kernel module source
- `Makefile` — Out-of-tree build
- `config-6.6.148.txt` — Minimal kernel config

## Related

- [qmi-fix-skbuild](https://github.com/vimsl/qmi-fix-skbuild)
- [Airpi-AP5000M-CloseWRT](https://github.com/vimsl/Airpi-AP5000M-CloseWRT)

## License

GPL-2.0