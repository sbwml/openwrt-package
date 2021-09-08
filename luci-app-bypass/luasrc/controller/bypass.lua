module("luci.controller.bypass",package.seeall)
local fs=require"nixio.fs"
local http=require"luci.http"
CALL=luci.sys.call
EXEC=luci.sys.exec
function index()
	if not nixio.fs.access("/etc/config/bypass") then
		return
	end
	local e=entry({"admin","services","bypass"},firstchild(),_("Bypass"),2)
	e.dependent=false
	e.acl_depends={"luci-app-bypass"}
	entry({"admin","services","bypass","base"},cbi("bypass/base"),_("Base Setting"),1).leaf=true
	entry({"admin","services","bypass","servers"},arcombine(cbi("bypass/servers",{autoapply=true}),cbi("bypass/client-config")),_("Severs Nodes"),2).leaf=true
	entry({"admin","services","bypass","shunt"},cbi("bypass/shunt"),_("Shunt Setting"),3).leaf=true
	entry({"admin","services","bypass","control"},cbi("bypass/control"),_("Access Control"),4).leaf=true
	entry({"admin","services","bypass","domain"},cbi("bypass/domain"),_("Domain List"),5).leaf=true
	entry({"admin","services","bypass","advanced"},cbi("bypass/advanced"),_("Advanced Settings"),6).leaf=true
	if luci.sys.call("which ssr-server >/dev/null")==0 or luci.sys.call("which ss-server >/dev/null")==0 or luci.sys.call("which microsocks >/dev/null")==0 then
		entry({"admin","services","bypass","server"},arcombine(cbi("bypass/server"),cbi("bypass/server-config")),_("Server"),7).leaf=true
	end
	entry({"admin","services","bypass","log"},form("bypass/log"),_("Log"),8).leaf=true
	entry({"admin", "services", "bypass", "run"}, call("act_status"))
	entry({"admin", "services", "bypass", "checknet"}, call("check_net"))
	entry({"admin","services","bypass","refresh"},call("refresh"))
	entry({"admin","services","bypass","subscribe"},call("subscribe"))
	entry({"admin","services","bypass","ping"},call("ping"))
	entry({"admin","services","bypass","getlog"},call("getlog"))
	entry({"admin","services","bypass","dellog"},call("dellog"))
end

function act_status()
    local e = {}
    e.tcp = CALL('busybox ps -w | grep bypass-tcp | grep -v grep  >/dev/null ') == 0
    e.udp = CALL('busybox ps -w | grep bypass-udp | grep -v grep  >/dev/null') == 0
    e.smartdns = CALL("pidof smartdns-le >/dev/null")==0

    e.chinadns=CALL("pidof chinadns-ng >/dev/null")==0
    http.prepare_content('application/json')
    http.write_json(e)
end


function check_net()
	local r=0
	local u=http.formvalue("url")
	local p
	if CALL("nslookup www."..u..".com >/dev/null 2>&1")==0 then
		if u=="google" then p="/generate_204" else p="" end
		r=EXEC("curl -m 5 -o /dev/null -sw %{time_starttransfer} http://www."..u..".com"..p.." | awk '{printf ($1*1000)}'")
		if r~="0" then
			r=EXEC("echo -n "..r.." | sed 's/\\..*//'")
			if r=="0" then r="1" end
		end
	end
	http.prepare_content("application/json")
	http.write_json({ret=r})
end


function refresh()
	local set=http.formvalue("set")
	local icount=0
	local r
	if set=="0" then
		sret=CALL("curl -Lfso /tmp/gfw.b64 https://cdn.jsdelivr.net/gh/Lj2x16sRVDNJcuBv/lgtOgNsB/IwocS3gciO/gVxoEuEit5EJeEm")
		if sret==0 then
			CALL("/usr/share/bypass/gfw")
			icount=EXEC("cat /tmp/gfwnew.txt | wc -l")
			if tonumber(icount)>1000 then
				oldcount=EXEC("cat /tmp/bypass/gfw.list | wc -l")
				if tonumber(icount)~=tonumber(oldcount) then
					EXEC("cp -f /tmp/gfwnew.txt /tmp/bypass/gfw.list && /etc/init.d/bypass restart >/dev/null 2>&1")
					r=tostring(tonumber(icount))
				else
					r="0"
				end
			else
				r="-1"
			end
			EXEC("rm -f /tmp/gfwnew.txt ")
		else
			r="-1"
		end
	elseif set=="1" then
		sret=CALL("A=`curl -Lfsm 9 https://cdn.jsdelivr.net/gh/Lj2x16sRVDNJcuBv/lgtOgNsB/IwocS3gciO/HbAsESdvo3K0mI4 || curl -Lfsm 9 https://raw.githubusercontent.com/Lj2x16sRVDNJcuBv/lgtOgNsB/master/IwocS3gciO/HbAsESdvo3K0mI4` && echo \"$A\" | base64 -d > /tmp/china.txt")
		icount=EXEC("cat /tmp/china.txt | wc -l")
		if sret==0 and tonumber(icount)>1000 then
			oldcount=EXEC("cat /tmp/bypass/china.txt | wc -l")
			if tonumber(icount)~=tonumber(oldcount) then
				EXEC("cp -f /tmp/china.txt /tmp/bypass/china.txt && ipset list china_v4 >/dev/null 2>&1 && /usr/share/bypass/chinaipset")
				r=tostring(tonumber(icount))
			else
				r="0"
			end
		else
			r="-1"
		end
		EXEC("rm -f /tmp/china.txt ")
	elseif set=="2" then
		sret=CALL("A=`curl -Lfsm 9 https://cdn.jsdelivr.net/gh/Lj2x16sRVDNJcuBv/lgtOgNsB/IwocS3gciO/vY3PHj8qJmtTXg6 || curl -Lfsm 9 https://raw.githubusercontent.com/Lj2x16sRVDNJcuBv/lgtOgNsB/master/IwocS3gciO/vY3PHj8qJmtTXg6` && echo \"$A\" | base64 -d > /tmp/china_v6.txt")
		icount=EXEC("cat /tmp/china_v6.txt | wc -l")
		if sret==0 and tonumber(icount)>1000 then
			oldcount=EXEC("cat /tmp/bypass/china_v6.txt | wc -l")
			if tonumber(icount)~=tonumber(oldcount) then
				EXEC("cp -f /tmp/china_v6.txt /tmp/bypass/china_v6.txt && ipset list china_v6 >/dev/null 2>&1 && /usr/share/bypass/chinaipset v6")
				r=tostring(tonumber(icount))
			else
				r="0"
			end
		else
			r="-1"
		end
		EXEC("rm -f /tmp/china_v6.txt ")
	end
	http.prepare_content("application/json")
	http.write_json({ret=r})
end

function subscribe()
	CALL("/usr/share/bypass/subscribe")
	http.prepare_content("application/json")
	http.write_json({ret=1})
end

function ping()
	local e = {}
	local domain = luci.http.formvalue("domain")
	local port = luci.http.formvalue("port")
	local transport = luci.http.formvalue("transport")
	local wsPath = luci.http.formvalue("wsPath")
	local tls = luci.http.formvalue("tls")
	e.index = luci.http.formvalue("index")
	local iret = luci.sys.call("ipset add ss_spec_wan_ac " .. domain .. " 2>/dev/null")
	if transport == "ws" then
		local prefix = tls=='1' and "https://" or "http://"
		local address = prefix..domain..':'..port..wsPath
		local result = luci.sys.exec("curl --http1.1 -m 2 -ksN -o /dev/null -w 'time_connect=%{time_connect}\nhttp_code=%{http_code}' -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==' -H 'Sec-WebSocket-Version: 13' "..address)
		e.socket = string.match(result,"http_code=(%d+)")=="101"
		e.ping = tonumber(string.match(result, "time_connect=(%d+.%d%d%d)"))*1000
	else
		local socket = nixio.socket("inet", "stream")
		socket:setopt("socket", "rcvtimeo", 3)
		socket:setopt("socket", "sndtimeo", 3)
		e.socket = socket:connect(domain, port)
		socket:close()
		-- 	e.ping = luci.sys.exec("ping -c 1 -W 1 %q 2>&1 | grep -o 'time=[0-9]*.[0-9]' | awk -F '=' '{print$2}'" % domain)
		-- 	if (e.ping == "") then
		e.ping = luci.sys.exec(string.format("echo -n $(tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null", port, domain))
		-- 	end
	end
	if (iret == 0) then
		luci.sys.call(" ipset del ss_spec_wan_ac " .. domain)
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function getlog()
	logfile="/tmp/bypass.log"
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
	fs.writefile("/tmp/bypass.log","")
	http.prepare_content("application/json")
	http.write('')
end
