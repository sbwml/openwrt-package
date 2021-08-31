# Copyright (C) 2008-2019 Jerrykuku
# Copyright (C) 2019-2021 sirpdboy
# http://www.github.com/sirpdboy/luci-theme-chuqitopd
# This is free software, licensed under the Apache License, Version 2.0 .

include $(TOPDIR)/rules.mk

THEME_NAME:=chuqitopd
THEME_TITLE:=chuqitopd Theme

PKG_NAME:=luci-theme-$(THEME_NAME)
PKG_VERSION:=1.1.7
PKG_RELEASE:=20210831

include $(INCLUDE_DIR)/package.mk

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-theme-chuqitopd/postinst
#!/bin/sh
sed -i ":a;$!N;s/tmpl.render.*sysauth_template.*return/local scope = { duser = default_user, fuser = user }\nlocal ok, res = luci.util.copcall\(luci.template.render_string, [[<% include\(\"themes\/\" .. theme .. \"\/sysauth\"\) %>]], scope\)\nif ok then\nreturn res\nend\nreturn luci.template.render\(\"sysauth\", scope\)/;ba" /usr/lib/lua/luci/dispatcher.lua
sed -i ":a;$!N;s/t.render.*sysauth_template.*return/local scope = { duser = h, fuser = a }\nlocal ok, res = luci.util.copcall\(luci.template.render_string, [[<% include\(\"themes\/\" .. theme .. \"\/sysauth\"\) %>]], scope\)\nif ok then\nreturn res\nend\nreturn luci.template.render\(\"sysauth\", scope\)/;ba" /usr/lib/lua/luci/dispatcher.lua
rm -Rf /var/luci-modulecache


endef
# call BuildPackage - OpenWrt buildroot signature
