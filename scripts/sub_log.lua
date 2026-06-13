-- Sub Log
local mp = require 'mp'

local last_text = ""
local enabled = false

local function log_subtitle(name, value)
    if not enabled then return end

    if value ~= nil and value ~= "" and value ~= last_text then
        last_text = value
        print(string.format("[%s] %s", mp.get_property_osd("time-pos"), value))
    end
end

local function toggle_logger()
    enabled = not enabled

    if enabled then
        last_text = ""
        mp.observe_property("sub-text", "string", log_subtitle)
        mp.osd_message("Subtitle logger: ON")
    else
        mp.unobserve_property(log_subtitle)
        mp.osd_message("Subtitle logger: OFF")
    end
end

mp.add_key_binding("Ctrl+s", "toggle-sub-logger", toggle_logger)
