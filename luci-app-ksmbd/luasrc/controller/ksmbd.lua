-- Licensed to the public under the Apache License 2.0.

module("luci.controller.ksmbd", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ksmbd") then
		return
	end
    entry({"admin", "control"}, firstchild(), "Control", 90).dependent = false
	local page

	page = entry({"admin", "nas", "ksmbd"}, cbi("ksmbd"), _("网络共享"))
	page.dependent = true
end

