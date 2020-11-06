#!/bin/bash
#=================================================
# Description: Build OpenWrt using GitHub Actions
# Author: sirpdboy
# https://github.com/sirpdboy/Openwrt
echo '修改banner'
cp -f diy/hong0980/banner package/base-files/files/etc/

rm -rf ./package/lean/luci-theme-argon
rm -rf ./package/lean/trojan
rm -rf ./package/lean/v2ray
rm -rf ./package/lean/v2ray-plugin
rm -rf ./package/lean/luci-app-netdata
rm -rf ./package/lean/luci-theme-opentomcat
rm -rf ./package/lean/luci-app-qbittorrent
rm -rf ./package/lean/qt5 #5.1.3
rm -rf ./package/lean/qBittorrent #4.2.3
#rm -rf ./feeds/diy/autocore
rm -rf ./package/lean/autocore
rm -rf ./package/lean/default-settings
rm -rf ./feeds/packages/utils/ttyd
rm -rf ./package/lean/luci-app-ttyd/root/etc/init.d/ttyd
sed -i 's/网络存储/存储/g' package/lean/luci-app-vsftpd/po/zh-cn/vsftpd.po
sed -i 's/Turbo ACC 网络加速/ACC网络加速/g' package/lean/luci-app-flowoffload/po/zh-cn/flowoffload.po
sed -i 's/Turbo ACC 网络加速/ACC网络加速/g' package/lean/luci-app-sfe/po/zh-cn/sfe.po
sed -i 's/解锁网易云灰色歌曲/解锁灰色歌曲/g' package/lean/luci-app-unblockmusic/po/zh-cn/unblockmusic.po
sed -i 's/家庭云//g' package/lean/luci-app-familycloud/luasrc/controller/familycloud.lua
sed -i '/filter_/d' package/network/services/dnsmasq/files/dhcp.conf
sed -i 's/$(VERSION_DIST_SANITIZED)/$(shell TZ=UTC-8 date +%Y%m%d)-ipv6/g' include/image.mk
echo "DISTRIB_REVISION='S$(TZ=UTC-8 date +%Y.%m.%d) Sirpdboy '" > ./package/base-files/files/etc/openwrt_release1
svn co https://github.com/sirpdboy/sirpdboy-package/trunk/adguardhome ./package/new/adguardhome
# curl -fsSL https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/anti-ad-smartdns.conf >  ./package/new/smartdns/conf/anti-ad-smartdns.conf
svn co https://github.com/jerrykuku/luci-app-jd-dailybonus/trunk/ ./package/new/luci-app-jd-dailybonus
git clone -b master --single-branch https://github.com/tty228/luci-app-serverchan ./package/new/luci-app-serverchan
git clone -b master --single-branch https://github.com/destan19/OpenAppFilter ./package/new/OpenAppFilter
git clone -b master https://github.com/vernesong/OpenClash.git package/OpenClash
git clone -b master --single-branch https://github.com/frainzy1477/luci-app-clash ./package/new/luci-app-clash
sed -i 's/), 5)/), 49)/g' package/new/luci-app-clash/luasrc/controller/clash.lua
sed -i 's/), 1)/), 49)/g' package/new/luci-app-clash/luasrc/controller/clash.lua
cp -f diy/hong0980/serverchan diy/luci-app-serverchan/root/etc/config/
svn co https://github.com/siropboy/luci-app-vssr-plus/trunk/  package/luci-app-vssr-plus
svn co https://github.com/xiaorouji/openwrt-package/trunk/lienol/luci-app-passwall package/luci-app-passwall
svn co https://github.com/xiaorouji/openwrt-package/trunk/package package/lienol
#sed -i 's/KERNEL_PATCHVER:=5.4/KERNEL_PATCHVER:=4.19/g' ./target/linux/x86/Makefile
#sed -i 's/KERNEL_TESTING_PATCHVER:=5.4/KERNEL_TESTING_PATCHVER:=4.19/g' ./target/linux/x86/Makefile
./scripts/feeds update -i
