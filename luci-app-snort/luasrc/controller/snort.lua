module("luci.controller.snort", package.seeall)

function index()

    if not nixio.fs.access("/etc/config/snort") then return end

    entry({"admin", "snort"}, firstchild(), "SNORT", 45).dependent = false
        entry({'admin', 'snort', 'snort'}, alias('admin', 'snort', 'snort', 'snort'), _('snort'), 10).dependent = true 
	entry({"admin","snort","snort","snort"},cbi("snort/snort"),_("snort"),10).dependent=true
	entry({"admin","snort","snort","log"},form("snort/log"),_("snort Log"),20).leaf=true
	entry({"admin", "snort", "snort", "snort_log"}, call("get_log")) 
end

function get_log()
    local fs = require "nixio.fs"
    local e = {}
    e.running = luci.sys.call("busybox ps -w | grep snort | grep -v grep >/dev/null") == 0
    e.log = fs.readfile("/var/log/tmpsnort.log") or ""
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
