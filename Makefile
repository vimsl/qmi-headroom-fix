# Makefile for standalone cross-compilation of qmi_fix_skb.ko
# Usage:
#   export KDIR=/path/to/linux-6.6.94
#   export CROSS_COMPILE=aarch64-openwrt-linux-musl-
#   export ARCH=arm64
#   make

obj-m := qmi_fix_skb.o

KDIR ?= /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
