local mp    = require 'mp'
local utils = require 'mp.utils'
local input = require 'mp.input'
local msg   = require 'mp.msg'

local CONFIG_FILE = mp.command_native({ "expand-path", "~~/server_ip.json" })
local LOCALHOST   = "http://127.0.0.1"

-- Simpan URL
local function save_url(url)
    local f = io.open(CONFIG_FILE, "w")
    if not f then
        print("[config_ip] ERROR: gagal membuka " .. CONFIG_FILE)
        mp.osd_message("Gagal menyimpan server")
        return
    end

    f:write(utils.format_json({
        url = url
    }))
    f:close()

    print("[config_ip] Server set:", url)
    mp.osd_message("Server:\n" .. url, 2)
end

-- Hapus config
local function delete_config()
    os.remove(CONFIG_FILE)
    print("[config_ip] Server BAD, config dihapus")
    mp.osd_message("Server tidak aktif, konfigurasi dihapus", 3)
end

-- Input URL
local function input_server_url()
    input.get({
        prompt = "Server URL: ",
        submit = function(text)
            input.terminate()

            text = (text or ""):match("^%s*(.-)%s*$")
            if text == "" then
                return
            end

            if not text:match("^https?://") then
                text = "http://" .. text
            end

            save_url(text)
        end
    })
end

-- Set localhost
local function use_localhost()
    save_url(LOCALHOST)
end

-- Cek server
local function check_server()
    print("[config_ip] check_server()")

    local f = io.open(CONFIG_FILE, "r")
    if not f then
        print("[config_ip] server_ip.json tidak ditemukan")
        return
    end

    local data = f:read("*all")
    f:close()

    print("[config_ip] json:", data)

    local json = utils.parse_json(data)

    if not json or not json.url then
        print("[config_ip] server_ip.json invalid")
        delete_config()
        return
    end

    local health_url = json.url .. ":5010/health"

    print("[config_ip] checking:", health_url)

    local res = utils.subprocess({
        args = {
            "curl",
            "-s",
            "--max-time", "2",
            health_url
        },
        cancellable = false
    })

    print("[config_ip] curl status:", res.status)
    print("[config_ip] curl stdout:", res.stdout)

    if res.status ~= 0 then
        print("[config_ip] SERVER BAD (curl gagal)")
        delete_config()
        return
    end

    local ok, body = pcall(utils.parse_json, res.stdout)

    if ok and body and body.status == "ok" then
        print("[config_ip] SERVER OK:", json.url)
    else
        print("[config_ip] SERVER BAD (response invalid)")
        delete_config()
    end
end

-- Jalankan setelah startup
mp.add_timeout(0, check_server)

-- Keybind
mp.add_key_binding("Ctrl+x", "input-server-url", input_server_url)
mp.add_key_binding("Alt+x", "use-localhost", use_localhost)