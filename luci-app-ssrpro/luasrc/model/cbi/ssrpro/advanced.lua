local cssr = 'ssrpro'
local uci = luci.model.uci.cursor()
local server_table = {}

local gfwmode = 0
local gfw_count = 0
local ip_count = 0
local ad_count = 0
local server_count = 0

if nixio.fs.access('/etc/ssrpro/gfw_list.conf') then
    gfwmode = 1
end
local sys = require 'luci.sys'
if gfwmode == 1 then
    gfw_count = tonumber(sys.exec('cat /etc/ssrpro/gfw_list.conf | wc -l')) / 2
    if nixio.fs.access('/etc/ssrpro/ad.conf') then
        ad_count = tonumber(sys.exec('cat /etc/ssrpro/ad.conf | wc -l'))
    end
end

if nixio.fs.access('/etc/ssrpro/china_ssr.txt') then
    ip_count = sys.exec('cat /etc/ssrpro/china_ssr.txt | wc -l')
end

uci:foreach(
    'ssrpro',
    'servers',
    function(s)
        server_count = server_count + 1
    end
)
uci:foreach(cssr, "servers", function(s)
	if s.alias then
		server_table[s[".name"]] = "[%s]:%s" % {string.upper(s.v2ray_protocol or s.type), s.alias}
	elseif s.server and s.server_port then
		server_table[s[".name"]] = "[%s]:%s:%s" % {string.upper(s.v2ray_protocol or s.type), s.server, s.server_port}
	end
end)

local key_table = {}
for key, _ in pairs(server_table) do
	table.insert(key_table, key)
end

table.sort(key_table)

m = Map(cssr)
-- [[ global ]]--
s = m:section(TypedSection, "global", translate("Server failsafe auto swith and custom update settings"))
s.anonymous = true

-- o = s:option(Flag, "monitor_enable", translate("Enable Process Deamon"))
-- o.rmempty = false
-- o.default = "1"

o = s:option(Flag, "enable_switch", translate("Enable Auto Switch"))
o.rmempty = false
o.default = "1"

o = s:option(Value, "switch_time", translate("Switch check cycly(second)"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 3600

o = s:option(Value, "switch_timeout", translate("Check timout(second)"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 5

o = s:option(Value, "switch_try_count", translate("Check Try Count"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 3

o = s:option(Value, "gfwlist_url", translate("gfwlist Update url"))
o:value("https://cdn.jsdelivr.net/gh/YW5vbnltb3Vz/domain-list-community@release/gfwlist.txt", translate("v2fly/domain-list-community"))
o:value("https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt", translate("Loyalsoldier/v2ray-rules-dat"))
o:value("https://cdn.jsdelivr.net/gh/Loukky/gfwlist-by-loukky/gfwlist.txt", translate("Loukky/gfwlist-by-loukky"))
o:value("https://cdn.jsdelivr.net/gh/gfwlist/gfwlist/gfwlist.txt", translate("gfwlist/gfwlist"))
o.default = "https://cdn.jsdelivr.net/gh/YW5vbnltb3Vz/domain-list-community@release/gfwlist.txt"

o = s:option(Value, "chnroute_url", translate("Chnroute Update url"))
o:value("https://ispip.clang.cn/all_cn.txt", translate("Clang.CN"))
o:value("https://ispip.clang.cn/all_cn_cidr.txt", translate("Clang.CN.CIDR"))
o.default = "https://ispip.clang.cn/all_cn.txt"

o = s:option(Flag, "netflix_enable", translate("Enable Netflix Mode"))
o.rmempty = false

o = s:option(Value, "nfip_url", translate("nfip_url"))
o:value("https://cdn.jsdelivr.net/gh/QiuSimons/Netflix_IP/NF_only.txt", translate("Netflix IP Only"))
o:value("https://cdn.jsdelivr.net/gh/QiuSimons/Netflix_IP/getflix.txt", translate("Netflix and AWS"))
o.default = "https://cdn.jsdelivr.net/gh/QiuSimons/Netflix_IP/NF_only.txt"
o.description = translate("Customize Netflix IP Url")
o:depends("netflix_enable", "1")

o = s:option(Flag, "adblock", translate("Enable adblock"))
o.rmempty = false

o = s:option(Value, "adblock_url", translate("adblock_url"))
o:value("https://neodev.team/lite_host_dnsmasq.conf", translate("NEO DEV HOST Lite"))
o:value("https://neodev.team/host_dnsmasq.conf", translate("NEO DEV HOST Full"))
o:value("https://anti-ad.net/anti-ad-for-dnsmasq.conf", translate("anti-AD"))
o.default = "https://neodev.team/lite_host_dnsmasq.conf"
o:depends("adblock", "1")
o.description = translate("Support AdGuardHome and DNSMASQ format list")

o = s:option(Button, "reset", translate("Reset to defaults"))
o.rawhtml = true
o.template = "ssrpro/reset"


o = s:option(Button, 'gfw_data', translate('GFW List Data'))
o.rawhtml = true
o.template = 'ssrpro/refresh'
o.value = tostring(math.ceil(gfw_count)) .. ' ' .. translate('Records')

o = s:option(Button, 'ip_data', translate('China IP Data'))
o.rawhtml = true
o.template = 'ssrpro/refresh'
o.value = ip_count .. ' ' .. translate('Records')

if uci:get_first(cssr, 'global', 'adblock', '') == '1' then
    o = s:option(Button, 'ad_data', translate('Advertising Data'))
    o.rawhtml = true
    o.template = 'ssrpro/refresh'
    o.value = ad_count .. ' ' .. translate('Records')
end

-- [[ SOCKS5 Proxy ]]--
s = m:section(TypedSection, "socks5_proxy", translate("Global SOCKS5 Proxy Server"))
s.anonymous = true

o = s:option(ListValue, "server", translate("Server"))
o:value("nil", translate("Disable"))
o:value("same", translate("Same as Global Server"))
for _, key in pairs(key_table) do
	o:value(key, server_table[key])
end
o.default = "nil"
o.rmempty = false

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.default = 1080
o.rmempty = false



return m
