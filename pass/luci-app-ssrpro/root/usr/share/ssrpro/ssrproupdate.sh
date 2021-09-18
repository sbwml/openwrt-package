#!/bin/sh
/usr/bin/lua /usr/share/ssrpro/update.lua
sleep 2s
/usr/share/ssrpro/chinaipset.sh /var/etc/ssrpro/china_ssr.txt
sleep 2s
/usr/bin/lua /usr/share/ssrpro/subscribe.lua
