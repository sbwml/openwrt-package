module('luci.controller.cssr', package.seeall)
local fs=require"nixio.fs"
local http=require"luci.http"
CALL=luci.sys.call
EXEC=luci.sys.exec
function index()
    if not nixio.fs.access('/etc/config/cssr') then
        return
    end

    if nixio.fs.access('/usr/bin/ssr-redir') then
        entry({'admin', 'services', 'cssr'}, alias('admin', 'services', 'cssr', 'client'), _('Bywall'), 0).dependent = true -- 首页
        entry({'admin', 'services', 'cssr', 'client'}, cbi('cssr/client'), _('SSR Client'), 10).leaf = true -- 基本设置
        entry({'admin', 'services', 'cssr', 'servers'}, cbi('cssr/servers'), _('Severs Nodes'), 11).leaf = true -- 服务器节点
        entry({'admin', 'services', 'cssr', 'servers'}, arcombine(cbi('cssr/servers'), cbi('cssr/client-config')), _('Severs Nodes'), 11).leaf = true -- 编辑节点
        entry({'admin', 'services', 'cssr', 'subscribe_config'}, cbi('cssr/subscribe-config', {hideapplybtn = true, hidesavebtn = true, hideresetbtn = true}), _('Subscribe'), 12).leaf = true -- 订阅设置
        entry({'admin', 'services', 'cssr', 'control'}, cbi('cssr/control'), _('Access Control'), 13).leaf = true -- 访问控制
        entry({'admin', 'services', 'cssr', 'router'}, cbi('cssr/router'), _('Router Config'), 14).leaf = true -- 访问控制
        if nixio.fs.access('/usr/bin/xray') then
            entry({'admin', 'services', 'cssr', 'socks5'}, cbi('cssr/socks5'), _('Local Proxy'), 15).leaf = true -- Socks5代理
        end
        entry({'admin', 'services', 'cssr', 'advanced'}, cbi('cssr/advanced'), _('Advanced Settings'), 16).leaf = true -- 高级设置
    elseif nixio.fs.access('/usr/bin/ssr-server') then
        entry({'admin', 'services', 'cssr'}, alias('admin', 'services', 'cssr', 'server'), _('cssr'), 10).dependent = true
    else
        return
    end
    if nixio.fs.access('/usr/bin/ssr-server') then
        entry({'admin', 'services', 'cssr', 'server'}, arcombine(cbi('cssr/server'), cbi('cssr/server-config')), _('SSR Server'), 20).leaf = true -- 服务端
    end

    entry({'admin', 'services', 'cssr', 'log'}, cbi('cssr/log'), _('Log'), 30).leaf = true -- 日志
    entry({"admin","services","cssr","status"},call("status"))

    entry({"admin","services","cssr","check"},call("check"))
    entry({'admin', 'services', 'cssr', 'refresh'}, call('refresh')) -- 更新白名单和GFWLIST
    entry({'admin', 'services', 'cssr', 'checkport'}, call('check_port')) -- 检测单个端口并返回Ping
    entry({'admin', 'services', 'cssr', 'run'}, call('act_status')) -- 检测全局服务器状态
    entry({'admin', 'services', 'cssr', 'change'}, call('change_node')) -- 切换节点
    entry({'admin', 'services', 'cssr', 'allserver'}, call('get_servers')) -- 获取所有节点Json
    entry({'admin', 'services', 'cssr', 'subscribe'}, call('get_subscribe')) -- 执行订阅
    entry({'admin', 'services', 'cssr', 'flag'}, call('get_flag')) -- 获取节点国旗 iso code
    entry({'admin', 'services', 'cssr', 'switch'}, call('switch')) -- 设置节点为自动切换
    entry({'admin', 'services', 'cssr', 'delnode'}, call('del_node')) -- 删除某个节点

    entry({"admin","services","cssr","getlog"},call("getlog"))  -- 获取日志
    entry({"admin","services","cssr","dellog"},call("dellog"))  -- 删除日志
end



function check()
	local r=0
	if CALL("nslookup www."..http.formvalue("url")..".com >/dev/null 2>&1")==0 then
		r=EXEC("curl -m 5 -o /dev/null -sw %{time_starttransfer} www."..http.formvalue("url")..".com | awk '{printf ($1*1000+0.5)}'")
		if r~="0" then
			r=EXEC("echo -n "..r.." | sed 's/\\..*//'")
			if r=="0" then r="1" end
		end
	end
	http.prepare_content("application/json")
	http.write_json({ret=r})
end

-- 执行订阅
function get_subscribe()
    local cjson = require 'luci.jsonc'
    local e = {}
    local name = 'cssr'
    local uci = luci.model.uci.cursor()
    local auto_update = luci.http.formvalue('auto_update')
    local auto_update_time = luci.http.formvalue('auto_update_time')
    local proxy = luci.http.formvalue('proxy')
    local subscribe_url = luci.http.formvalue('subscribe_url')
    local filter_words = luci.http.formvalue('filter_words')
    if subscribe_url ~= '[]' then
        uci:delete(name, '@server_subscribe[0]', subscribe_url)
        uci:set(name, '@server_subscribe[0]', 'auto_update', auto_update)
        uci:set(name, '@server_subscribe[0]', 'auto_update_time', auto_update_time)
        uci:set(name, '@server_subscribe[0]', 'proxy', proxy)
        uci:set(name, '@server_subscribe[0]', 'filter_words', filter_words)
        uci:set_list(name, '@server_subscribe[0]', 'subscribe_url', cjson.parse(subscribe_url))
        uci:commit(name)
       EXEC('/usr/bin/lua /usr/share/cssr/subscribe.lua >/www/check_update.htm 2>/dev/null &')
        e.error = 0
    else
        e.error = 1
    end
    luci.http.prepare_content('application/json')
    luci.http.write_json(e)
end

-- 获取所有节点
function get_servers()
    local uci = luci.model.uci.cursor()
    local server_table = {}
    uci:foreach(
        'cssr',
        'servers',
        function(s)
            local e = {}
            e['name'] = s['.name']
            table.insert(server_table, e)
        end
    )
    luci.http.prepare_content('application/json')
    luci.http.write_json(server_table)
end

-- 删除指定节点
function del_node()
    local e = {}
    local uci = luci.model.uci.cursor()
    local node = luci.http.formvalue('node')
    e.status = false
    e.node = node
    if node ~= '' then
        uci:delete('cssr', node)
        uci:save('cssr')
        uci:commit('cssr')
        e.status = true
    end
    luci.http.prepare_content('application/json')
    luci.http.write_json(e)
end

-- 切换节点
function change_node()
    local sockets = require 'socket'
    local e = {}
    local uci = luci.model.uci.cursor()
    local sid = luci.http.formvalue('set')
    local server = luci.http.formvalue('server')
    e.status = false
    e.sid = sid
    if sid ~= '' and server ~= '' then
        uci:set('cssr', '@global[0]', server .. '_server', sid)
        if (server ~= 'global' and server ~= 'udp_relay') then
            uci:set('cssr', '@global[0]', 'v2ray_flow', '1')
        end
        uci:commit('cssr')
        CALL('/etc/init.d/cssr restart >/www/restartlog.htm 2>&1')
        e.status = true
    end
    luci.http.prepare_content('application/json')
    luci.http.write_json(e)
end

-- 设置节点为自动切换
function switch()
    local e = {}
    local uci = luci.model.uci.cursor()
    local sid = luci.http.formvalue('node')
    local isSwitch = uci:get('cssr', sid, 'switch_enable')
    local toSwitch = (isSwitch == '1') and '0' or '1'
    uci:set('cssr', sid, 'switch_enable', toSwitch)
    uci:commit('cssr')
    if isSwitch == '1' then
        e.switch = false
    else
        e.switch = true
    end
    e.status = true
    luci.http.prepare_content('application/json')
    luci.http.write_json(e)
end

-- 检测全局服务器状态
function act_status()
    math.randomseed(os.time())
    local e = {}
    -- 全局服务器
    e.global = CALL('busybox ps -w | grep cssr_t | grep -v grep  >/dev/null ') == 0
    -- 检测PDNSD状态
    e.pdnsd = CALL('busybox ps -w | grep pdnsdc | grep -v grep  >/dev/null ') == 0
    -- 检测游戏模式状态
    e.game = CALL('busybox ps -w | grep cssr_u | grep -v grep  >/dev/null') == 0
    -- 检测Socks5
    e.socks5 = CALL('busybox ps -w | grep cssr_s | grep -v grep  >/dev/null') == 0
    luci.http.prepare_content('application/json')
    luci.http.write_json(e)
end

-- 检测单个节点状态并返回连接速度
function check_port()
    local sockets = require 'socket'
    local cssr = require 'cssrutil'
    local set = luci.http.formvalue('host')
    local port = luci.http.formvalue('port')
    local retstring = ''
    local t0 = sockets.gettime()
    ret = cssr.check_site(set, port)
    local t1 = sockets.gettime()
    retstring = tostring(ret) == 'true' and '1' or '0'
    local tt = t1 - t0
    luci.http.prepare_content('application/json')
    luci.http.write_json({ret = retstring, used = math.floor(tt * 1000 + 0.5)})
end

function get_iso(ip)
    local mm = require 'maxminddb'
    local db = mm.open('/usr/share/cssr/GeoLite2-Country.mmdb')
    local res = db:lookup(ip)
    return string.lower(res:get('country', 'iso_code'))
end

function get_cname(ip)
    local mm = require 'maxminddb'
    local db = mm.open('/usr/share/cssr/GeoLite2-Country.mmdb')
    local res = db:lookup(ip)
    return string.lower(res:get('country', 'names', 'zh-CN'))
end


-- 获取节点国旗 iso code
function get_flag()
    local e = {}
    local cssr = require 'cssrutil'
    local host = luci.http.formvalue('host')
    local remark = luci.http.formvalue('remark')
    e.host = host
    e.flag = cssr.get_flag(remark, host)
    luci.http.prepare_content('application/json')
    luci.http.write_json(e)
end

-- 刷新检测文件

function refresh()
    local set = luci.http.formvalue('set')
    local icount = 0

    if set == 'gfw_data' then
        refresh_cmd = 'wget-ssl --no-check-certificate https://cdn.jsdelivr.net/gh/gfwlist/gfwlist/gfwlist.txt -O /tmp/gfw.b64'
        sret = CALL(refresh_cmd .. ' 2>/dev/null')
        if sret == 0 then
            CALL('/usr/bin/cssr-gfw')
            icount =EXEC('cat /tmp/gfwnew.txt | wc -l')
            if tonumber(icount) > 1000 then
                oldcount =EXEC('cat /etc/cssr/gfw_list.conf | wc -l')
                if tonumber(icount) ~= tonumber(oldcount) then
                   EXEC('cp -f /tmp/gfwnew.txt /etc/cssr/gfw_list.conf')
                    retstring = tostring(math.ceil(tonumber(icount) / 2))
                else
                    retstring = '0'
                end
            else
                retstring = '-1'
            end
           EXEC('rm -f /tmp/gfwnew.txt ')
        else
            retstring = '-1'
        end
    elseif set == 'ip_data' then
        refresh_cmd = "wget-ssl -O- 'https://ispip.clang.cn/all_cn.txt' > /tmp/china_ssr.txt 2>/dev/null"
        sret = CALL(refresh_cmd)
        icount =EXEC('cat /tmp/china_ssr.txt | wc -l')
        if sret == 0 and tonumber(icount) > 1000 then
            oldcount =EXEC('cat /etc/cssr/china_ssr.txt | wc -l')
            if tonumber(icount) ~= tonumber(oldcount) then
               EXEC('cp -f /tmp/china_ssr.txt /etc/cssr/china_ssr.txt')
                retstring = tostring(tonumber(icount))
            else
                retstring = '0'
            end
        else
            retstring = '-1'
        end
       EXEC('rm -f /tmp/china_ssr.txt ')
    else
        local need_process = 0
        refresh_cmd = 'wget-ssl --no-check-certificate -O - https://easylist-downloads.adblockplus.org/easylistchina+easylist.txt > /tmp/adnew.conf'
        need_process = 1
        sret = CALL(refresh_cmd .. ' 2>/dev/null')
        if sret == 0 then
            if need_process == 1 then
                CALL('/usr/bin/cssr-ad')
            end
            icount =EXEC('cat /tmp/ad.conf | wc -l')
            if tonumber(icount) > 1000 then
                if nixio.fs.access('/etc/cssr/ad.conf') then
                    oldcount =EXEC('cat /etc/cssr/ad.conf | wc -l')
                else
                    oldcount = 0
                end
                if tonumber(icount) ~= tonumber(oldcount) then
                   EXEC('cp -f /tmp/ad.conf /etc/cssr/ad.conf')
                    retstring = tostring(math.ceil(tonumber(icount)))
                    if oldcount == 0 then
                        CALL('/etc/init.d/dnsmasq restart')
                    end
                else
                    retstring = '0'
                end
            else
                retstring = '-1'
            end
           EXEC('rm -f /tmp/ad.conf')
        else
            retstring = '-1'
        end
    end
    luci.http.prepare_content('application/json')
    luci.http.write_json({ret = retstring, retcount = icount})
end

function ping()
	local e={}
	local domain=http.formvalue("domain")
	local port=http.formvalue("port")
	local dp=EXEC("netstat -unl | grep 5336 >/dev/null && echo -n 5336 || echo -n 53")
	local ip=EXEC("echo "..domain.." | grep -E ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ || \\\
	nslookup "..domain.." 127.0.0.1#"..dp.." 2>/dev/null | grep Address | awk -F' ' '{print$NF}' | grep -E ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ | sed -n 1p")
	ip=EXEC("echo -n "..ip)
	local iret=CALL("ipset add over_wan_ac "..ip.." 2>/dev/null")
	e.ping=EXEC(string.format("tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}'",port,ip))
	if (iret==0) then
		CALL("ipset del over_wan_ac "..ip)
	end
	http.prepare_content("application/json")
	http.write_json(e)
end

function getlog()
	logfile="/tmp/cssr.log"
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
	fs.writefile("/tmp/cssr.log","")
	http.prepare_content("application/json")
	http.write('')
end
