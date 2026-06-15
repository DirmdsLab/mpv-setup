local mp    = require 'mp'
local utils = require 'mp.utils'

local CONFIG_FILE = mp.command_native({"expand-path", "~~/server_ip.json"})

local function get_server()
    local f = io.open(CONFIG_FILE, "r")
    if not f then
        return nil
    end

    local data = f:read("*all")
    f:close()

    local json = utils.parse_json(data)

    return json and json.url
end

local function show_server()
    local server = get_server()

    if server then
        mp.osd_message("Server:\n" .. server, 3)
    else
        mp.osd_message("Server belum diset", 3)
    end
end

mp.add_key_binding("Ctrl+y", "show-server", show_server)