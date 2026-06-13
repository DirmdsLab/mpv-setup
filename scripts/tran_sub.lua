-- mpv_translate_trans_persist_osd_space.lua
local mp = require 'mp'
local utils = require 'mp.utils'

local FONT_SIZE = 50
local OFFSET_X = 20
local OFFSET_Y = 120

local COLORS = {
    reset = "\27[0m",
    blue_title = "\27[34m",
    blue_text  = "\27[36m",
    green_title= "\27[32m",
    green_text = "\27[92m",
    yellow = "\27[33m"
}

-- ==========================================================
-- 'trans' (translate-shell)
-- ==========================================================
local function translate_text(text)
    -- `trans -b -s en -t id <teks>`
    local res = utils.subprocess({
        args = {"trans", "-b", "-s", "en", "-t", "id", text},
        cancellable = false
    })

    if res.status == 0 then
        return res.stdout:gsub("\n","")
    end
    return text
end

-- Print 
local function print_highlight(original, translated)
    print(COLORS.blue_title.."Original:"..COLORS.reset)
    print(COLORS.blue_text..original..COLORS.reset)
    print(COLORS.green_title.."Translated:"..COLORS.reset)
    print(COLORS.green_text..translated..COLORS.reset)
    print("--------------------\n")
end

-- OSD
local function show_translate_osd(text)
    local w = mp.get_property_number("dwidth",1920)
    local h = mp.get_property_number("dheight",1080)

    local ass_text = string.format("{\\fs%d\\an7\\pos(%d,%d)}%s", FONT_SIZE, OFFSET_X, OFFSET_Y, text)
    mp.set_osd_ass(w,h,ass_text)
end

-- Get Subs
local function get_current_subtitle()
    local sub = mp.get_property("sub-text")
    if not sub or sub == "" then
        return nil
    end

    local lines = {}
    for line in sub:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    return table.concat(lines, " ")
end

-- Pause video
local function pause_video()
    local paused = mp.get_property_native("pause")
    if not paused then
        mp.set_property_native("pause", true)
    end
end

-- Clear OSD
local function clear_osd()
    mp.set_osd_ass(mp.get_property_number("dwidth",1920), mp.get_property_number("dheight",1080), "")
end

-- OSD + Console
local function translate_osd_and_terminal()
    pause_video()
    local subtitle = get_current_subtitle()
    if not subtitle then
        local msg = "No subtitle found at current frame"
        print(COLORS.yellow..msg..COLORS.reset)
        show_translate_osd(msg)
        return
    end

    local translated = translate_text(subtitle)
    print_highlight(subtitle, translated)
    show_translate_osd(translated)
end

-- Console Only
local function translate_terminal_only()
    pause_video()
    local subtitle = get_current_subtitle()
    if not subtitle then
        local msg = "No subtitle found at current frame"
        print(COLORS.yellow..msg..COLORS.reset)
        show_translate_osd(msg)
        return
    end

    local translated = translate_text(subtitle)
    print_highlight(subtitle, translated)
end

-- Keybind
mp.add_key_binding("y","translate_osd_and_terminal",translate_osd_and_terminal)
mp.add_key_binding("Ctrl+O","translate_terminal_only",translate_terminal_only)

-- Clear
mp.observe_property("pause","bool",function(_, paused)
    if paused == false then
        clear_osd()
    end
end)

