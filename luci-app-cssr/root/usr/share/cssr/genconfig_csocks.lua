local ucursor = require 'luci.model.uci'.cursor()
local json = require 'luci.jsonc'
local server_section = arg[1]
local host = arg[4]
local server = ucursor:get_all('cssr', server_section)

local csocks = {

    tls_ip = server.tls_ip,
    tls_host =host,
    port = server.server_port,
    out_addr =server.out_addr,
    uuid =server.vmess_id
}
print(json.stringify(csocks, 1))
