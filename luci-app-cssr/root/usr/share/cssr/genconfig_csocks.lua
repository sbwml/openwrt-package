local ucursor = require 'luci.model.uci'.cursor()
local json = require 'luci.jsonc'
local server_section = arg[1]

local server = ucursor:get_all('cssr', server_section)

local csocks = {
    out_addr =server.out_addr
    tls_ip = server.tls_ip,
    tls_host = server.tls_host,
    port = server.server_port,
    uuid =server.vmess_id
}
print(json.stringify(csocks, 1))
