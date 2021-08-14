module("luci.controller.ssrpro",package.seeall)
local fs=require"nixio.fs"
local http=require"luci.http"
CALL=luci.sys.call
EXEC=luci.sys.exec
function index()
	if not nixio.fs.access("/etc/config/ssrpro") then
		call("act_reset")
	end

	local page = entry({"admin", "services", "ssrpro"}, alias("admin", "services", "ssrpro", "client"), _("SSRPRO"), 1)
	page.dependent = false
	page.acl_depends = { "luci-app-ssrpro" }
	entry({"admin", "services", "ssrpro", "client"}, cbi("ssrpro/client"), _("SSR Client"), 10).leaf = true
	entry({"admin", "services", "ssrpro", "servers"}, arcombine(cbi("ssrpro/servers", {autoapply = true}), cbi("ssrpro/client-config")), _("Severs Nodes"), 20).leaf = true
	entry({"admin", "services", "ssrpro", "control"}, cbi("ssrpro/control"), _("Access Control"), 40).leaf = true
	entry({"admin", "services", "ssrpro", "advanced"}, cbi("ssrpro/advanced"), _("Advanced Settings"), 50).leaf = true

	if luci.sys.call("which ssr-server >/dev/null")==0 or luci.sys.call("which ss-server >/dev/null")==0 or luci.sys.call("which microsocks >/dev/null")==0 then
	entry({"admin", "services", "ssrpro", "server"}, arcombine(cbi("ssrpro/server"), cbi("ssrpro/server-config")), _("SSR Server"), 60).leaf = true
	end
        entry({'admin', 'services', 'ssrpro', 'log'}, cbi('ssrpro/log'), _('Log'), 70).leaf = true
	entry({"admin", "services", "ssrpro", "checknet"}, call("check_net"))
	entry({"admin", "services", "ssrpro", "refresh"}, call("refresh_data"))
	entry({"admin", "services", "ssrpro", "subscribe"}, call("subscribe"))
	entry({"admin", "services", "ssrpro", "run"}, call("act_status"))
	entry({"admin", "services", "ssrpro", "ping"}, call("act_ping"))
	entry({"admin", "services", "ssrpro", "reset"}, call("act_reset"))
	entry({"admin", "services", "ssrpro", "restart"}, call("act_restart"))
	entry({"admin", "services", "ssrpro", "delete"}, call("act_delete"))
	entry({"admin", "services", "ssrpro", "cache"}, call("act_cache"))

	 entry({"admin","services","ssrpro","getlog"},call("getlog")) 
         entry({"admin","services","ssrpro","dellog"},call("dellog")) 
end

function subscribe()
	CALL("/usr/bin/lua /usr/share/ssrpro/subscribe.lua >>/var/log/ssrpro.log")
	http.prepare_content("application/json")
	http.write_json({ret = 1})
end

function check_net()
	local r=0
	if CALL("nslookup www."..http.formvalue("url")..".com >/dev/null 2>&1")==0 then
		r=EXEC("curl -m 5 -o /dev/null -sw %{time_starttransfer} www."..http.formvalue("url")..".com | awk '{printf ($1*1000)}'")
		if r~="0" then
			r=EXEC("echo -n "..r.." | sed 's/\\..*//'")
			if r=="0" then r="1" end
		end
	end
	http.prepare_content("application/json")
	http.write_json({ret=r})

end
function act_status()
    math.randomseed(os.time())
    local e = {}

    e.global = CALL('busybox ps -w | grep ssrpro- | grep -v grep  >/dev/null ') == 0

    e.pdnsd = CALL('busybox ps -w | grep pdnsds | grep -v grep  >/dev/null ') == 0

    e.udp = CALL('busybox ps -w | grep ssrpro-reudp | grep -v grep  >/dev/null') == 0

    e.server= CALL('busybox ps -w | grep ssr-server | grep -v grep  >/dev/null') == 0
    http.prepare_content('application/json')
    http.write_json(e)
end

function act_ping()
	local e = {}
	local domain = http.formvalue("domain")
	local port = http.formvalue("port")
	local transport = http.formvalue("transport")
	local wsPath = http.formvalue("wsPath")
	local tls = http.formvalue("tls")
	e.index = http.formvalue("index")
	local iret = CALL("ipset add ss_spec_wan_ac " .. domain .. " 2>/dev/null")
	if transport == "ws" then
		local prefix = tls=='1' and "https://" or "http://"
		local address = prefix..domain..':'..port..wsPath
		local result = EXEC("curl --http1.1 -m 2 -ksN -o /dev/null -w 'time_connect=%{time_connect}\nhttp_code=%{http_code}' -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==' -H 'Sec-WebSocket-Version: 13' "..address)
		e.socket = string.match(result,"http_code=(%d+)")=="101"
		e.ping = tonumber(string.match(result, "time_connect=(%d+.%d%d%d)"))*1000
	else
		local socket = nixio.socket("inet", "stream")
		socket:setopt("socket", "rcvtimeo", 3)
		socket:setopt("socket", "sndtimeo", 3)
		e.socket = socket:connect(domain, port)
		socket:close()
		-- 	e.ping = EXEC("ping -c 1 -W 1 %q 2>&1 | grep -o 'time=[0-9]*.[0-9]' | awk -F '=' '{print$2}'" % domain)
		-- 	if (e.ping == "") then
		e.ping = EXEC(string.format("echo -n $(tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null", port, domain))
		-- 	end
	end
	if (iret == 0) then
		CALL(" ipset del ss_spec_wan_ac " .. domain)
	end
	http.prepare_content("application/json")
	http.write_json(e)
end


function refresh_data()
	local set = http.formvalue("set")
	local retstring = loadstring("return " .. EXEC("/usr/bin/lua /usr/share/ssrpro/update.lua " .. set))()
	http.prepare_content("application/json")
	http.write_json(retstring)
end

function act_reset()
	CALL("/etc/init.d/ssrpro reset &")
	http.redirect(luci.dispatcher.build_url("admin", "services", "ssrpro"))
end

function act_restart()
	CALL("/etc/init.d/ssrpro restart &")
	http.redirect(luci.dispatcher.build_url("admin", "services", "ssrpro"))
end

function act_delete()
	CALL("/etc/init.d/ssrpro restart &")
	http.redirect(luci.dispatcher.build_url("admin", "services", "ssrpro", "servers"))
end

function act_cache()
	local e = {}
	e.ret = CALL("pdnsd-ctl -c /var/etc/ssrpro/pdnsds empty-cache >/dev/null")
	http.prepare_content("application/json")
	http.write_json(e)
end

function getlog()
	logfile="/var/log/ssrpro.log"
	if not fs.access(logfile) then
		http.write("")
		return
	end
	local f=io.open(logfile,"r")
	local a=f:read("*a") or ""
	f:close()
	a=string.gsub(a,"\n$","")
	http.prepare_content("text/plain; charset=utf-8")
	http.write(a)
end

function dellog()
	fs.writefile("/var/log/ssrpro.log","")
	http.prepare_content("application/json")
	http.write('')
end