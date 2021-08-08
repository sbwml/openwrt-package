include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-cssr
PKG_VERSION:=1
PKG_RELEASE:=4
PKG_DATE:=20210807

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/config
config PACKAGE_$(PKG_NAME)_INCLUDE_Xray
	bool "Include Xray"
	default y if i386||x86_64||arm||aarch64

config PACKAGE_$(PKG_NAME)_INCLUDE_Trojan
	bool "Include Trojan"
	default y if i386||x86_64||arm||aarch64
	
config PACKAGE_$(PKG_NAME)_INCLUDE_Kcptun
	bool "Include Kcptun"
	default n

config PACKAGE_$(PKG_NAME)_INCLUDE_Xray_plugin
	bool "Include Shadowsocks Xray Plugin"
	default y if i386||x86_64||arm||aarch64
	
config PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR_Libev_Server
	bool "Include ShadowsocksR Libev Server"
	default y if i386||x86_64||arm||aarch64
endef

PKG_CONFIG_DEPENDS:= \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Xray \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Trojan \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Kcptun \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Xray_plugin \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR_Libev_Server

define Package/luci-app-cssr
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=A New SS/SSR/Xray/Trojan LuCI interface
	PKGARCH:=all
	DEPENDS:=+ipset +ip-full +iptables-mod-tproxy +dnsmasq-full +coreutils +coreutils-base64 +bash +pdnsd-alt +wget-ssl +lua +luasocket +lua-maxminddb \
			+shadowsocks-libev-ss-local +shadowsocks-libev-ss-redir +shadowsocksr-libev-ssr-local +shadowsocksr-libev-ssr-redir +shadowsocksr-libev-ssr-check +simple-obfs \
			+PACKAGE_$(PKG_NAME)_INCLUDE_Xray:xray-core \
			+PACKAGE_$(PKG_NAME)_INCLUDE_Trojan:trojan \
			+PACKAGE_$(PKG_NAME)_INCLUDE_Trojan:ipt2socks \
			+PACKAGE_$(PKG_NAME)_INCLUDE_Kcptun:kcptun-client \
			+PACKAGE_$(PKG_NAME)_INCLUDE_Xray_plugin:xray-plugin \
			+PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR_Libev_Server:shadowsocksr-libev-ssr-server
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/luci-app-cssr/conffiles
	/etc/cssr/
	/etc/config/cssr
endef

define Package/luci-app-cssr/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/
	cp -pR ./root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh-cn/cssr.po $(1)/usr/lib/lua/luci/i18n/cssr.zh-cn.lmo
endef

define Package/luci-app-cssr/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-cssr ) && rm -f /etc/uci-defaults/luci-cssr
	rm -rf /tmp/luci-indexcache
	rm -rf /tmp/luci-modulecache/*
	chmod 755 /etc/init.d/cssr >/dev/null 2>&1
	/etc/init.d/cssr enable >/dev/null 2>&1
fi
exit 0
endef

define Package/luci-app-cssr/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
     /etc/init.d/cssr disable
     /etc/init.d/cssr stop
fi
exit 0
endef

$(eval $(call BuildPackage,luci-app-cssr))
