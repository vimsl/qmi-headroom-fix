# qmi-headroom-fix

Kprobe-based kernel module to fix QMI WWAN skb headroom issues on MediaTek MT798x 5G CPE platforms (Hiveton **H5000M** + Fibocom FM170-EAU via the closed-source `qmi_wwan_f` driver).

> This repo previously had a sibling build-environment repo (`qmi-fix-skbuild`). That repo has been merged into this one and archived — everything lives here now.

## Problem

The closed-source `qmi_wwan_f` driver allocates sk_buffs without reserving sufficient headroom (`LL_MAX_HEADER` = 176 bytes). When HNAT/PPE hardware acceleration tries to append headers, the driver's own tailroom check (`skb_tailroom small!`) fails and packets are dropped.

## Solution

Uses Linux kprobes to intercept skb allocation (`__alloc_skb` mandatory, `__netdev_alloc_skb` optional). When the caller is `qmi_wwan_f`, 176 bytes are added to the requested size so the tailroom check passes. No driver binary patching needed — works across driver rebuilds.

## Repo Layout

```
qmi_fix_skb.c            # Kernel module source (v3)
Makefile                 # Out-of-tree build
config-6.6.94.txt        # Kernel config for module compilation (6.6.94)
config-6.6.148.txt       # Kernel config for module compilation (6.6.148)
install-and-test.sh      # On-router install & verification script
package/qmi_fix_skb/     # OpenWrt kernel package (kmod-qmi-fix-skb)
.github/workflows/
  build.yml              # CI: cross-compile qmi_fix_skb.ko for ARM64 -> Release
  build-hnat-usb0.yml    # CI: full ImmortalWrt H5000M firmware (HNAT usb0 + AIQoS)
```

## CI Build

Two workflows, both manual-trigger (`workflow_dispatch`):

1. **`build.yml`** — downloads Linux kernel 6.6.148, cross-compiles `qmi_fix_skb.ko` for ARM64, creates a GitHub release with the module.
2. **`build-hnat-usb0.yml`** — builds a complete ImmortalWrt `openwrt-25.12` firmware for Hiveton H5000M:
   - Applies ImmortalWrt PR#2166 (H5000M support)
   - Injects `ext-devices = "usb0"` into the HNAT DTS node
   - Adds the QModem feed
   - Bundles cake-autorate + AIQoS (luci-app-aiqos), alist, samba4, ttyd

## OpenWrt Package Build

Drop `package/qmi_fix_skb/` into an ImmortalWrt/OpenWrt tree, then:

```bash
make package/qmi_fix_skb/compile V=s
```

The module autoloads at boot (`AutoLoad 99`).

## On-Router Install & Test

```sh
insmod qmi_fix_skb.ko
sh install-and-test.sh
```

Verify:
- `cat /sys/module/qmi_fix_skb/parameters/count` — fix applications counter (should grow under load)
- `dmesg | grep skb_tailroom` — tailroom errors should stop growing
- `dmesg | grep qmi_fix_skb` — module messages

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

## Related

- [H5000M-FM170eau](https://github.com/vimsl/H5000M-FM170eau) — the device firmware project (ImmortalWrt/CloseWRT cloud build). Embeds this module as `package/qmi_fix_skb/`; it also carries the AI QoS stack (`package/aiqos-engine/`) and the AIQoS whitepaper under `docs/`.
- The firmware repo also keeps a **driver-source patch** route (`patches/qmi-wwan-tailroom.patch`, `Scripts/fix-qmi-skb.patch`) for the same problem. This repo (kprobe, no driver rebuild) is the single upstream for the hotfix module; keep only one route active in a given build.

## License

GPL-2.0
