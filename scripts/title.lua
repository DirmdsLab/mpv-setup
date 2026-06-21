local mp    = require 'mp'
local utils = require 'mp.utils'

local PORT = 5010

local CONFIG_FILE = mp.command_native({
    "expand-path",
    "~~/server_ip.json"
})

local function get_server()

    local f = io.open(CONFIG_FILE, "r")

    if not f then
        mp.msg.error("Config tidak ditemukan: " .. CONFIG_FILE)
        return nil
    end

    local data = f:read("*all")
    f:close()

    local json = utils.parse_json(data)

    if not json or not json.url then
        mp.msg.error("URL server tidak valid")
        return nil
    end

    return json.url
end

local function send_title()

    local server = get_server()

    if not server then
        return
    end

    local endpoint = server .. ":" .. PORT .. "/title"

    local title =
        mp.get_property("filename")
        or mp.get_property("media-title")
        or ""

    if title == "" then
        mp.msg.error("Judul kosong")
        return
    end

    local payload = utils.format_json({
        title = title
    })

    mp.msg.info("Sending title: " .. title)
    mp.msg.info("Endpoint: " .. endpoint)

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = {
            "curl",
            "-s",
            "-X", "POST",
            "-H", "Content-Type: application/json",
            "-d", payload,
            endpoint
        }
    },
    function(success, result, err)

        if not success then
            mp.msg.error("Request gagal: " .. tostring(err))
            return
        end

        if result.stdout and result.stdout ~= "" then
            mp.msg.info("Response: " .. result.stdout)
        end

        if result.stderr and result.stderr ~= "" then
            mp.msg.error(result.stderr)
        end

    end)

end

mp.register_event("file-loaded", send_title)