-- Licensed to the public under the GNU General Public License v3.
local m, s, o
local cssr = 'cssr'
local json = require 'luci.jsonc'

local uci = luci.model.uci.cursor()
local server_count = 0
local server_table = {}
uci:foreach(
    'cssr',
    'servers',
    function(s)
        server_count = server_count + 1
        s['name'] = s['.name']
        if(s.alias == nil) then
            s.alias = "未命名节点"
        end
        table.insert(server_table, s)
    end
)

local name = ''
uci:foreach(
    'cssr',
    'global',
    function(s)
        name = s['.name']
    end
)
function my_sort(a,b)
    if(a.alias ~= nil and b.alias ~= nil) then
        return  a.alias < b.alias
    end
end
table.sort(server_table, my_sort)
m = Map(cssr)

m:section(SimpleSection).template = 'cssr/status'

-- [[ Servers List ]]--
s = m:section(TypedSection, 'servers')
s.anonymous = true
s.addremove = true
s.sortable = false

s.des = server_count
s.current = uci:get('cssr', name, 'global_server')
s.serverTable = server_table
s.servers = json.stringify(server_table)
s.template = 'cssr/tblsection'
s.extedit = luci.dispatcher.build_url('admin/services/cssr/servers/%s')
function s.create(...)
    local sid = TypedSection.create(...)
    if sid then
        luci.http.redirect(s.extedit % sid)
        return
    end
end

return m
