#!/bin/sh
. $IPKG_INSTROOT/etc/init.d/ssrpro
netflix() {
	if [ -f "$TMP_DNSMASQ_PATH/gfw_list.conf" ]; then
		for line in $(cat /etc/ssrpro/netflix.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/gfw_list.conf; done
		for line in $(cat /etc/ssrpro/netflix.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/gfw_base.conf; done
	fi
	cat /etc/ssrpro/netflix.list | sed '/^$/d' | sed '/#/d' | sed "/.*/s/.*/server=\/&\/127.0.0.1#$1\nipset=\/&\/netflix/" >$TMP_DNSMASQ_PATH/netflix_forward.conf
}
mkdir -p $TMP_DNSMASQ_PATH
if [ "$(uci_get_by_type global run_mode router)" == "oversea" ]; then
	cp -rf /etc/ssrpro/oversea_list.conf $TMP_DNSMASQ_PATH/
else
	cp -rf /etc/ssrpro/gfw_list.conf $TMP_DNSMASQ_PATH/
	cp -rf /etc/ssrpro/gfw_base.conf $TMP_DNSMASQ_PATH/
fi
case "$(uci_get_by_type global netflix_server nil)" in
nil)
	rm -f $TMP_DNSMASQ_PATH/netflix_forward.conf
	;;
$(uci_get_by_type global global_server nil) | $switch_server | same)
	netflix $dns_port
	;;
*)
	netflix $tmp_shunt_dns_port
	;;
esac
for line in $(cat /etc/ssrpro/black.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/gfw_list.conf; done
for line in $(cat /etc/ssrpro/black.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/gfw_base.conf; done
for line in $(cat /etc/ssrpro/white.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/gfw_list.conf; done
for line in $(cat /etc/ssrpro/white.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/gfw_base.conf; done
for line in $(cat /etc/ssrpro/deny.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/gfw_list.conf; done
for line in $(cat /etc/ssrpro/deny.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/gfw_base.conf; done
cat /etc/ssrpro/black.list | sed '/^$/d' | sed '/#/d' | sed "/.*/s/.*/server=\/&\/127.0.0.1#$dns_port\nipset=\/&\/blacklist/" >$TMP_DNSMASQ_PATH/blacklist_forward.conf
cat /etc/ssrpro/white.list | sed '/^$/d' | sed '/#/d' | sed "/.*/s/.*/server=\/&\/127.0.0.1\nipset=\/&\/whitelist/" >$TMP_DNSMASQ_PATH/whitelist_forward.conf
cat /etc/ssrpro/deny.list | sed '/^$/d' | sed '/#/d' | sed "/.*/s/.*/address=\/&\//" >$TMP_DNSMASQ_PATH/denylist.conf
if [ "$(uci_get_by_type global adblock 0)" == "1" ]; then
	cp -f /etc/ssrpro/ad.conf $TMP_DNSMASQ_PATH/
	if [ -f "$TMP_DNSMASQ_PATH/ad.conf" ]; then
		for line in $(cat /etc/ssrpro/black.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/ad.conf; done
		for line in $(cat /etc/ssrpro/white.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/ad.conf; done
		for line in $(cat /etc/ssrpro/deny.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/ad.conf; done
		for line in $(cat /etc/ssrpro/netflix.list); do sed -i "/$line/d" $TMP_DNSMASQ_PATH/ad.conf; done
	fi
else
	rm -f $TMP_DNSMASQ_PATH/ad.conf
fi
