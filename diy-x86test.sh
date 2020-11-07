echo '修改banner'
cp -f ./package/sirpdboy/banner ./package/base-files/files/etc/
echo '修改时区'
sed -i "s/'UTC'/'CST-8'\n        set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate
echo '添加软件包'
git clone https://github.com/sirpdboy/sirpbboy-package ./package/diy
svn co https://github.com/xiaorouji/openwrt-package/trunk/lienol/luci-app-passwall package/luci-app-passwall
svn co https://github.com/xiaorouji/openwrt-package/trunk/package package/lienol
#sed -i '$a\chdbits.co\n\www.cnscg.club\n\pt.btschool.club\n\et8.org\n\www.nicept.net\n\pthome.net\n\ourbits.club\n\pt.m-team.cc\n\hdsky.me\n\ccfbits.org' ./package/luci-app-passwall/root/usr/share/passwall/rules/direct_host
#sed -i '$a\docker.com\n\docker.io' ./package/luci-app-passwall/root/usr/share/passwall/rules/proxy_host
#sed -i '/global_rules/a option auto_update 1\n option week_update 0\n option time_update 5' ./package/luci-app-passwall/root/etc/config/passwall
#sed -i '/global_subscribe/a option auto_update_subscribe 1\noption week_update_subscribe 7\noption time_update_subscribe 5' ./package/luci-app-passwall/root/etc/config/passwall

#rm -rf package/lean/v2ray && svn co https://github.com/xiaorouji/openwrt-package/trunk/package/v2ray diy/v2ray
#rm -rf package/lean/v2ray-plugin && svn co https://github.com/xiaorouji/openwrt-package/trunk/package/v2ray-plugin diy/v2ray-plugin
#svn co https://github.com/xiaorouji/openwrt-package/trunk/package/ssocks ./package/lienol/ssocks
#svn co https://github.com/xiaorouji/openwrt-package/trunk/package/trojan-plus ./package/lienol/trojan-plus
#svn co https://github.com/xiaorouji/openwrt-package/trunk/package/trojan-go ./package/lienol/trojan-go
#svn co https://github.com/siropboy/luci-app-vssr-plus/trunk/  package/luci-app-vssr-plus

rm -rf ./package/lean/luci-theme-argon
rm -rf ./package/lean/trojan
rm -rf ./package/lean/v2ray
rm -rf ./package/lean/v2ray-plugin
rm -rf ./package/lean/luci-app-netdata
rm -rf ./package/lean/luci-theme-opentomcat
rm -rf ./package/sirpdboy/qbittorrent
rm -rf ./package/sirpdboy/qt5
rm -rf ./package/sirpdboy/autocore
rm -rf ./package/sirpdboy/autocore
rm -rf ./package/sirpdboy/autocore
#rm -rf ./package/lean/autocore
rm -rf ./package/lean/default-settings
# rm -rf ./feeds/packages/utils/ttyd
# rm -rf ./lean/luci-app-ttyd/root/etc/init.d/ttyd
sed -i 's/网络存储/存储/g' package/lean/luci-app-vsftpd/po/zh-cn/vsftpd.po
sed -i 's/Turbo ACC 网络加速/ACC网络加速/g' package/lean/luci-app-flowoffload/po/zh-cn/flowoffload.po
sed -i 's/Turbo ACC 网络加速/ACC网络加速/g' package/lean/luci-app-sfe/po/zh-cn/sfe.po
sed -i 's/解锁网易云灰色歌曲/解锁灰色歌曲/g' package/lean/luci-app-unblockmusic/po/zh-cn/unblockmusic.po
sed -i 's/家庭云//g' ./package/lean/luci-app-familycloud/luasrc/controller/familycloud.lua
sed -i '/filter_/d' ./package/network/services/dnsmasq/files/dhcp.conf
sed -i 's/$(VERSION_DIST_SANITIZED)/$(shell TZ=UTC-8 date +%Y%m%d)-ipv6-Mini/g' include/image.mk
echo "DISTRIB_REVISION='S$(TZ=UTC-8 date +%Y.%m.%d) ipv6-Mini'" > ./package/base-files/files/etc/openwrt_release1

./scripts/feeds update -i