local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local input = require 'mp.input'

local FONT_SIZE = 50
local OFFSET_X = 20
local OFFSET_Y = 120

local server_url = nil

-- ==========================================================
-- OSD
-- ==========================================================

local function show_osd(text)
    local w = mp.get_property_number("dwidth",1920)
    local h = mp.get_property_number("dheight",1080)
    local ass = string.format("{\\fs%d\\an7\\pos(%d,%d)}%s",
        FONT_SIZE, OFFSET_X, OFFSET_Y, text)
    mp.set_osd_ass(w,h,ass)
end

local function clear_osd()
    mp.set_osd_ass(
        mp.get_property_number("dwidth",1920),
        mp.get_property_number("dheight",1080),
        ""
    )
end

-- ==========================================================
-- SUBTITLE
-- ==========================================================

local function get_current_subtitle()
    local sub = mp.get_property("sub-text")
    if not sub or sub == "" then return nil end

    local lines = {}
    for line in sub:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    return table.concat(lines, " ")
end

local function pause_video()
    if not mp.get_property_native("pause") then
        mp.set_property_native("pause", true)
    end
end

-- ==========================================================
-- TRANSLATE VIA SERVER
-- ==========================================================

local function translate_text(text)
    if not server_url then
        show_osd("Server URL belum diset! (Ctrl+t)")
        return nil
    end

    local res = utils.subprocess({
        args = {
            "curl",
            "-s",
            "-X", "POST",
            server_url .. "/translate",
            "-H", "Content-Type: application/json",
            "-d", utils.format_json({text = text})
        },
        cancellable = false
    })

    if res.status == 0 then
        local parsed = utils.parse_json(res.stdout)
        if parsed and parsed.translated then
            return parsed.translated
        end
    end

    return nil
end

-- ==========================================================
-- ACTIONS
-- ==========================================================

local function translate_osd_and_terminal()
    pause_video()

    local subtitle = get_current_subtitle()
    if not subtitle then
        show_osd("No subtitle found")
        return
    end

    show_osd("Translating...")

    local translated = translate_text(subtitle)
    if translated then
        print("Original: "..subtitle)
        print("Translated: "..translated)
        show_osd(translated)
    else
        show_osd("Translate failed")
    end
end

local function translate_terminal_only()
    pause_video()

    local subtitle = get_current_subtitle()
    if not subtitle then
        print("No subtitle found")
        return
    end

    local translated = translate_text(subtitle)
    if translated then
        print("Original: "..subtitle)
        print("Translated: "..translated)
    else
        print("Translate failed")
    end
end

-- ==========================================================
-- INPUT URL (NO HISTORY)
-- ==========================================================

local function input_server_url()
    input.get({
        prompt = "Enter Server IP: ",
        submit = function(text)
            input.terminate()

            if text and text ~= "" then
                -- hapus spasi di awal/akhir
                text = text:match("^%s*(.-)%s*$")

                -- kalau user belum menulis http:// atau https://
                if not text:match("^https?://") then
                    text = "http://" .. text
                end

                -- tambahkan port default kalau belum ada
                if not text:match(":%d+$") then
                    text = text .. ":5010"
                end

                server_url = text
                show_osd("Server set:\n" .. server_url)
            end
        end
    })
end

-- ==========================================================
-- KEYBIND
-- ==========================================================

mp.add_key_binding("t", "translate_osd", translate_osd_and_terminal)
mp.add_key_binding("Ctrl+Shift+t", "translate_terminal", translate_terminal_only)
mp.add_key_binding("Ctrl+t", "set_server_url", input_server_url)

mp.observe_property("pause","bool",function(_, paused)
    if paused == false then
        clear_osd()
    end
end)
