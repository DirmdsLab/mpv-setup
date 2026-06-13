local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local input = require 'mp.input'

local FONT_SIZE = 50
local OFFSET_X = 20
local OFFSET_Y = 120

local server_url = nil
local server_initialized = false

local DEFAULT_SERVER = "http://127.0.0.1:5010"

local realtime_enabled = false
local last_sub = nil


--------------------------------------------------
-- CONFIG
--------------------------------------------------

local OUTPUT = "/tmp/sub.vtt"
local OUTPUT_TRANS = "/tmp/trans.vtt"
local DUMP_SPEED = 10

--------------------------------------------------
-- STATE
--------------------------------------------------

local enabled = false
local timer = nil

local saved_speed = 1
local saved_keep_open = "no"

local current_text = ""
local current_start = nil


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

local function check_server()

    if server_initialized then
        return true
    end

    show_osd("Set server dulu! (Ctrl+t)\natau Alt+t untuk localhost")
    print("Server belum diinisialisasi")

    return false
end

local function guarded(fn)
    return function(...)
        if not check_server() then
            return
        end

        return fn(...)
    end
end

local function use_default_server()

    server_url = DEFAULT_SERVER
    server_initialized = true

    show_osd("Server set:\n" .. server_url)

    print("Using default server: "..server_url)
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

local function get_sub()

    local sub = mp.get_property("sub-text") or ""

    sub = sub:gsub("\r", " ")
    sub = sub:gsub("\n", " ")

    return sub
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
-- NORMAL TRANSLATE (T)
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
        print("Original: " .. subtitle)
        print("Translated: " .. translated)
        show_osd(translated)
    else
        show_osd("Translate failed")
    end
end

-- ==========================================================
-- TERMINAL ONLY (Ctrl+Shift+T MODE OFFLINE)
-- (dipertahankan untuk manual single shot)
-- ==========================================================

local function translate_terminal_only()
    pause_video()

    local subtitle = get_current_subtitle()
    if not subtitle then
        print("No subtitle found")
        return
    end

    local translated = translate_text(subtitle)
    if translated then
        print("Original: " .. subtitle)
        print("Translated: " .. translated)
    else
        print("Translate failed")
    end
end

-- ==========================================================
-- REALTIME TRANSLATE (TERMINAL ONLY)
-- Ctrl+Shift+T -> toggle mode
-- ==========================================================

local function realtime_translate_handler()
    if not realtime_enabled then return end

    local subtitle = get_current_subtitle()
    if not subtitle or subtitle == last_sub then
        return
    end

    last_sub = subtitle

    local translated = translate_text(subtitle)
    if translated then
        print("[REALTIME]")
        print("Original: " .. subtitle)
        print("Translated: " .. translated)
        print("----------------------------")
    end
end

local function toggle_realtime_translate()
    realtime_enabled = not realtime_enabled

    if realtime_enabled then
        mp.observe_property("sub-text", "string", realtime_translate_handler)
        print("Realtime translate: ON (terminal only)")
    else
        mp.unobserve_property(realtime_translate_handler)
        last_sub = nil
        print("Realtime translate: OFF")
    end
end


-- ==========================================================
-- QUICK TRANSLATE INPUT (Ctrl + Alt + T)
-- ==========================================================

local function quick_translate_submit(text)
    input.terminate()

    if not text or text == "" then
        return
    end

    text = text:match("^%s*(.-)%s*$")

    show_osd("Translating...")

    local translated = translate_text(text)

    if translated then
        print("Quick Translate")
        print("Original: " .. text)
        print("Translated: " .. translated)

        show_osd(translated)
    else
        print("Translate failed")
        show_osd("Translate failed")
    end
end

local function quick_translate_input()
    pause_video()

    input.get({
        prompt = "Translate text: ",
        submit = quick_translate_submit
    })
end

-- ==========================================================
-- INPUT URL
-- ==========================================================

local function input_server_url()
    input.get({
        prompt = "Enter Server IP [127.0.0.1:5010]: ",
        submit = function(text)
            input.terminate()

            text = (text or ""):match("^%s*(.-)%s*$")

            if text == "" then
                server_url = DEFAULT_SERVER
            else
                if not text:match("^https?://") then
                    text = "http://" .. text
                end

                if not text:match(":%d+$") then
                    text = text .. ":5010"
                end

                server_url = text
            end

            server_initialized = true

            show_osd("Server set:\n" .. server_url)
        end
    })
end

-- dump 

--------------------------------------------------
-- FILE
--------------------------------------------------

local function clear_file()
    local f = io.open(OUTPUT, "w")
    if f then
        f:write("WEBVTT\n\n")
        f:close()
    end
end

local function format_time(sec)

    sec = sec or 0

    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60

    return string.format("%02d:%02d:%06.3f", h, m, s)
end

local function append_vtt(start_t, end_t, text)

    if text == "" then
        return
    end

    local f = io.open(OUTPUT, "a")
    if not f then
        return
    end

    f:write(format_time(start_t))
    f:write(" --> ")
    f:write(format_time(end_t))
    f:write("\n")
    f:write(text)
    f:write("\n\n")

    f:close()
end

--------------------------------------------------
-- SUB
--------------------------------------------------



--------------------------------------------------
-- FLUSH
--------------------------------------------------


local function translate_vtt_file()

    local f = io.open(OUTPUT, "r")
    if not f then
        return false
    end

    local out = io.open(OUTPUT_TRANS, "w")
    if not out then
        f:close()
        return false
    end

    out:write("WEBVTT\n\n")

    local timestamp = nil

    for line in f:lines() do

        -- skip WEBVTT dan blank
        if line ~= "" and line ~= "WEBVTT" then

            if line:find("-->") then
                timestamp = line

            elseif timestamp then

                print("[SEND]")
                print(line)

                local translated = translate_text(line)

                if not translated then
                    translated = line
                end

                print("[RECV]")
                print(translated)

                out:write(timestamp .. "\n")
                out:write(translated .. "\n\n")

                timestamp = nil
            end
        end
    end

    f:close()
    out:close()

    return true
end

local function attach_translated_sub()
    mp.commandv(
        "sub-add",
        OUTPUT_TRANS,
        "select",
        "Translated"
    )

    print("Attached: "..OUTPUT_TRANS)
end

local function flush_current()

    if current_text == "" or current_start == nil then
        return
    end

    local end_time = mp.get_property_number("time-pos", current_start)

    append_vtt(current_start, end_time, current_text)

    print("[VTT] " .. current_text)

    current_text = ""
    current_start = nil
end


--------------------------------------------------
-- STOP / RESTORE
--------------------------------------------------

local function stop_dump()

    if not enabled then
        return
    end

    enabled = false

    if timer then
        timer:kill()
        timer = nil
    end

    flush_current()

    print("TRANSLATING...")

    if translate_vtt_file() then
        attach_translated_sub()
    end

    print("===================================")
    print("DUMP COMPLETE")
    print("RESTORE PLAYER")
    print("===================================")

    mp.set_property("vid", "auto")
    mp.set_property_number("speed", saved_speed)

    if saved_keep_open then
        mp.set_property("keep-open", saved_keep_open)
    end

    -- kembali ke awal video
    mp.commandv("seek", 0, "absolute")

    -- pause di awal
    mp.set_property("pause", "yes")

    print("===================================")
    print("RESET TO START")
    print("VIDEO RESTORED")
    print("===================================")
end

--------------------------------------------------
-- LOOP
--------------------------------------------------

local function tick()

    if not enabled then
        return
    end

    ------------------------------------------------
    -- EOF DETECT
    ------------------------------------------------

    if mp.get_property_bool("eof-reached", false) then

        print("===================================")
        print("EOF DETECTED")
        print("===================================")

        stop_dump()
        return
    end

    local sub = get_sub()
    local pos = mp.get_property_number("time-pos", 0)

    ------------------------------------------------
    -- START
    ------------------------------------------------

    if current_text == "" and sub ~= "" then

        current_text = sub
        current_start = pos

        print("[START] " .. sub)

        return
    end

    ------------------------------------------------
    -- CHANGE
    ------------------------------------------------

    if current_text ~= "" and sub ~= "" and sub ~= current_text then

        flush_current()

        current_text = sub
        current_start = pos

        print("[CHANGE] " .. sub)

        return
    end

    ------------------------------------------------
    -- DISAPPEAR
    ------------------------------------------------

    if current_text ~= "" and sub == "" then

        flush_current()

        return
    end
end



--------------------------------------------------
-- TOGGLE
--------------------------------------------------

local function toggle()

    if enabled then
        stop_dump()
        return
    end

    enabled = true

    clear_file()

    current_text = ""
    current_start = nil

    saved_speed = mp.get_property_number("speed", 1)
    saved_keep_open = mp.get_property("keep-open")

    print("===================================")
    print("VTT DUMP MODE")
    print("VIDEO OFF")
    print("SPEED x" .. DUMP_SPEED)
    print("===================================")

    mp.set_property("keep-open", "yes")

    -- mulai dari awal video
    mp.commandv("seek", 0, "absolute")

    mp.set_property("vid", "no")
    mp.set_property_number("speed", DUMP_SPEED)
    mp.set_property("pause", "no")

    timer = mp.add_periodic_timer(0.02, tick)
end



--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

mp.register_event("shutdown", function()

    if timer then
        timer:kill()
    end

    mp.set_property("vid", "auto")
    mp.set_property_number("speed", 1)
end)



-- ==========================================================
-- KEYBIND
-- ==========================================================

mp.add_key_binding("t",
    "translate_osd",
    guarded(translate_osd_and_terminal))

mp.add_key_binding("Ctrl+Shift+t",
    "realtime_translate",
    guarded(toggle_realtime_translate))

mp.add_key_binding("Ctrl+Alt+t",
    "quick_translate_input",
    guarded(quick_translate_input))

mp.add_key_binding("Ctrl+Shift+Alt+t",
    "dump_vtt_realtime",
    guarded(toggle))

-- portal manual
mp.add_key_binding("Ctrl+t",
    "set_server_url",
    input_server_url)

-- bypass localhost
mp.add_key_binding("Alt+t",
    "default_server",
    use_default_server)



mp.observe_property("pause","bool",function(_, paused)
    if paused == false then
        clear_osd()
    end
end)