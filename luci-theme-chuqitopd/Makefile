# Copyright (C) 2008-2019 Jerrykuku
# Copyright (C) 2019-2021 sirpdboy
# http://www.github.com/sirpdboy/luci-theme-chuqitopd
# This is free software, licensed under the Apache License, Version 2.0 .

include $(TOPDIR)/rules.mk

THEME_NAME:=chuqitopd
THEME_TITLE:=chuqitopd Theme

PKG_NAME:=luci-theme-$(THEME_NAME)
PKG_VERSION:=1.2.1
PKG_RELEASE:=20210905

include $(INCLUDE_DIR)/package.mk

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-theme-chuqitopd/postinst
#!/bin/sh

rm -Rf /var/luci-modulecache
rm -Rf /var/luci-indexcache
exit 0

endef
# call BuildPackage - OpenWrt buildroot signature
