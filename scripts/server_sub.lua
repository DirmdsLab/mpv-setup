local mp    = require 'mp'
local utils = require 'mp.utils'
local msg   = require 'mp.msg'
local input = require 'mp.input'

-- ==========================================================
-- CONFIG
-- ==========================================================

local FONT_SIZE  = 50
local OFFSET_X   = 20
local OFFSET_Y   = 120
local DUMP_SPEED = 10

local DEFAULT_SERVER = "http://127.0.0.1:5010"

local function get_tmp_dir()
    if package.config:sub(1, 1) == "\\" then
        return os.getenv("TEMP") or os.getenv("TMP") or "C:\\Temp"
    end
    return os.getenv("TMPDIR") or "/tmp"
end

local TMP          = get_tmp_dir()
local OUTPUT       = TMP .. "/sub.vtt"
local OUTPUT_TRANS = TMP .. "/trans.vtt"
local STATE_FILE   = TMP .. "/trans.state"

-- ==========================================================
-- STATE
-- ==========================================================

local server_url         = nil
local server_initialized = false
local realtime_enabled   = false
local last_sub           = nil

local enabled         = false
local timer           = nil
local saved_speed     = 1
local saved_keep_open = "no"
local current_text    = ""
local current_start   = nil

-- Translation progress
-- last_translate_index: line-number of the last *successfully* translated content line
-- failed_index:         line-number of the line that failed (nil = no failure)
local last_translate_index = 0
local failed_index         = nil

-- ==========================================================
-- OSD
-- ==========================================================

local function show_osd(text)
    local w = mp.get_property_number("dwidth",  1920)
    local h = mp.get_property_number("dheight", 1080)
    mp.set_osd_ass(w, h, string.format("{\\fs%d\\an7\\pos(%d,%d)}%s",
        FONT_SIZE, OFFSET_X, OFFSET_Y, text))
end

local function clear_osd()
    mp.set_osd_ass(
        mp.get_property_number("dwidth",  1920),
        mp.get_property_number("dheight", 1080), "")
end

-- ==========================================================
-- SERVER
-- ==========================================================

local function check_server()
    if server_initialized then return true end
    show_osd("Set server dulu! (Ctrl+t)\natau Alt+t untuk localhost")
    msg.warn("Server belum diinisialisasi")
    return false
end

local function guarded(fn)
    return function(...)
        if check_server() then return fn(...) end
    end
end

local function use_default_server()
    server_url         = DEFAULT_SERVER
    server_initialized = true
    show_osd("Server set:\n" .. server_url)
    msg.info("Default server: " .. server_url)
end

local function input_server_url()
    input.get({
        prompt = "Server IP [127.0.0.1:5010]: ",
        submit = function(text)
            input.terminate()
            text = (text or ""):match("^%s*(.-)%s*$")
            if text == "" then
                server_url = DEFAULT_SERVER
            else
                if not text:match("^https?://") then text = "http://" .. text end
                if not text:match(":%d+$")       then text = text .. ":5010"   end
                server_url = text
            end
            server_initialized = true
            show_osd("Server set:\n" .. server_url)
        end
    })
end

-- ==========================================================
-- SUBTITLE HELPERS
-- ==========================================================

local function get_current_subtitle()
    local sub = mp.get_property("sub-text")
    if not sub or sub == "" then return nil end
    return (sub:gsub("[\r\n]+", " "):match("^%s*(.-)%s*$"))
end

local function get_sub()
    return (mp.get_property("sub-text") or ""):gsub("[\r\n]+", " ")
end

local function pause_video()
    if not mp.get_property_native("pause") then
        mp.set_property_native("pause", true)
    end
end

-- ==========================================================
-- HTTP TRANSLATE
-- ==========================================================

local function translate_text(text)
    if not server_url then
        show_osd("Server belum diset! (Ctrl+t)")
        return nil
    end
    local res = utils.subprocess({
        args = {
            "curl", "-s", "-X", "POST",
            server_url .. "/translate",
            "-H", "Content-Type: application/json",
            "-d", utils.format_json({ text = text })
        },
        cancellable = false
    })
    if res.status == 0 then
        local ok, parsed = pcall(utils.parse_json, res.stdout)
        if ok and parsed and parsed.translated then
            return parsed.translated
        end
    end
    return nil
end

-- ==========================================================
-- INTERACTIVE TRANSLATE MODES
-- ==========================================================

-- t → translate current subtitle to OSD
local function translate_osd()
    pause_video()
    local sub = get_current_subtitle()
    if not sub then show_osd("No subtitle found"); return end
    show_osd("Translating...")
    local tr = translate_text(sub)
    if tr then
        msg.info("Orig:  " .. sub)
        msg.info("Trans: " .. tr)
        show_osd(tr)
    else
        show_osd("Translate failed")
    end
end

-- Ctrl+Shift+T → toggle realtime translation (terminal)
local function realtime_handler()
    if not realtime_enabled then return end
    local sub = get_current_subtitle()
    if not sub or sub == last_sub then return end
    last_sub = sub
    local tr = translate_text(sub)
    if tr then msg.info("[RT] " .. sub .. " → " .. tr) end
end

local function toggle_realtime()
    realtime_enabled = not realtime_enabled
    if realtime_enabled then
        mp.observe_property("sub-text", "string", realtime_handler)
        msg.info("Realtime: ON")
    else
        mp.unobserve_property(realtime_handler)
        last_sub = nil
        msg.info("Realtime: OFF")
    end
end

-- Ctrl+Alt+T → translate user-typed text to OSD
local function quick_translate_input()
    pause_video()
    input.get({
        prompt = "Translate: ",
        submit = function(text)
            input.terminate()
            text = (text or ""):match("^%s*(.-)%s*$")
            if text == "" then return end
            show_osd("Translating...")
            local tr = translate_text(text)
            if tr then
                msg.info("Quick: " .. text .. " → " .. tr)
                show_osd(tr)
            else
                show_osd("Translate failed")
            end
        end
    })
end

-- ==========================================================
-- VTT FILE HELPERS
-- ==========================================================

local function format_time(sec)
    sec = sec or 0
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    return string.format("%02d:%02d:%06.3f", h, m, s)
end

local function write_vtt_header(path)
    local f = io.open(path, "w")
    if f then f:write("WEBVTT\n\n"); f:close(); return true end
    return false
end

local function append_vtt(start_t, end_t, text)
    if text == "" then return end
    local f = io.open(OUTPUT, "a")
    if not f then return end
    f:write(format_time(start_t) .. " --> " .. format_time(end_t) .. "\n"
            .. text .. "\n\n")
    f:close()
end

-- ==========================================================
-- STATE PERSISTENCE
--
-- FIX #1 (ordering): reset_translate_state defined HERE, before any caller.
-- In the original it was defined after reset_dump_files(), making the local
-- invisible to callers → resolved as global → nil → runtime crash.
--
-- FIX #2 (persistence): failed_index is now saved/loaded from the state file.
-- Previously it was in-memory only, so a process restart wiped it and resume
-- could not know which line to skip/retry.
-- ==========================================================

local function save_state()
    local f = io.open(STATE_FILE, "w")
    if not f then return end
    f:write(last_translate_index .. "\n")
    f:write((failed_index or 0) .. "\n")   -- FIX: persist failed_index
    f:close()
end

local function load_state()
    local f = io.open(STATE_FILE, "r")
    if not f then return end
    local vals = {}
    for line in f:lines() do vals[#vals + 1] = tonumber(line) or 0 end
    f:close()
    last_translate_index = math.max(0, vals[1] or 0)
    local fi = vals[2] or 0
    failed_index = fi > 0 and fi or nil
    msg.info("[STATE] loaded  last=" .. last_translate_index
             .. "  failed=" .. (failed_index or "nil"))
end

local function reset_translate_state()
    last_translate_index = 0
    failed_index         = nil
    os.remove(STATE_FILE)
    msg.info("[STATE] reset")
end

-- ==========================================================
-- BULK VTT TRANSLATION  (dump → trans)
-- ==========================================================

local function translate_vtt_file()
    local src = io.open(OUTPUT, "r")
    if not src then
        msg.error("[TRANSLATE] cannot open source: " .. OUTPUT)
        return false
    end

    -- Decide fresh write vs append-for-resume
    local resuming = last_translate_index > 0

    -- FIX #3 (missing file guard): if we think we're resuming but OUTPUT_TRANS
    -- no longer exists, starting in append mode would create a file without the
    -- WEBVTT header → invalid VTT. Reset to fresh instead.
    if resuming then
        local probe = io.open(OUTPUT_TRANS, "r")
        if probe then
            probe:close()
        else
            msg.warn("[TRANSLATE] trans file missing → resetting to fresh start")
            resuming             = false
            last_translate_index = 0
            failed_index         = nil
        end
    end

    local dst = io.open(OUTPUT_TRANS, resuming and "a" or "w")
    if not dst then
        src:close()
        msg.error("[TRANSLATE] cannot open dest: " .. OUTPUT_TRANS)
        return false
    end
    if not resuming then dst:write("WEBVTT\n\n") end

    local timestamp = nil
    local index     = 0
    local success   = true

    for line in src:lines() do
        index = index + 1

        -- Always skip blank lines and the WEBVTT header marker
        if line == "" or line == "WEBVTT" then goto continue end

        -- Skip lines that were already successfully translated in a prior run
        if index <= last_translate_index then goto continue end

        -- Safety net: skip the known-broken line without crashing the loop.
        -- The user must press Alt+Shift+T (resume binding) to clear this lock
        -- and actually retry the line.
        if failed_index and index == failed_index then
            timestamp = nil  -- discard stale timestamp so next cue starts clean
            goto continue
        end

        if line:find("-->", 1, true) then
            timestamp = line

        elseif timestamp then
            msg.info("[SEND] " .. line)
            local tr = translate_text(line)

            if not tr then
                -- ============================================================
                -- BUG FIX #4 (main resume bug):
                --
                -- Original code:  last_translate_index = index - 1
                -- This set last_translate_index to the *timestamp* line.
                -- On the next resume:
                --   • index <= last_translate_index skipped the timestamp line
                --   • the text line was then reached with timestamp == nil
                --   • the cue was silently dropped, translation never retried
                --
                -- Fix: do NOT touch last_translate_index on failure.
                -- It already points to the last *successfully* translated line.
                -- The next resume will therefore see the timestamp → text pair
                -- and retry the translation correctly.
                -- ============================================================
                failed_index = index
                save_state()
                success = false
                msg.warn("[FAIL] index=" .. index .. " | " .. line)
                break
            end

            msg.info("[RECV] " .. tr)
            dst:write(timestamp .. "\n" .. tr .. "\n\n")
            last_translate_index = index
            failed_index         = nil
            save_state()
            timestamp = nil
        end

        ::continue::
    end

    src:close()
    dst:close()

    if success then
        failed_index = nil
        msg.info("[DONE] translation complete — " .. last_translate_index .. " lines")
    else
        msg.warn("[PAUSED] last_ok=" .. last_translate_index
                 .. "  failed_at=" .. (failed_index or "?"))
    end

    return success
end

local function attach_translated_sub()
    mp.commandv("sub-add", OUTPUT_TRANS, "select", "Translated")
    msg.info("Attached: " .. OUTPUT_TRANS)
end

-- ==========================================================
-- DUMP LOOP
-- ==========================================================

local function flush_current()
    if current_text == "" or current_start == nil then return end
    local end_t = mp.get_property_number("time-pos", current_start)
    append_vtt(current_start, end_t, current_text)
    msg.info("[VTT] " .. current_text)
    current_text  = ""
    current_start = nil
end

local function stop_dump()
    if not enabled then return end
    enabled = false

    if timer then timer:kill(); timer = nil end

    flush_current()

    msg.info("=== TRANSLATING ===")
    if translate_vtt_file() then
        attach_translated_sub()
        show_osd("Selesai!")
    else
        show_osd("Translate gagal!\nAlt+Shift+T untuk lanjut")
    end

    -- Restore player state
    mp.set_property("vid", "auto")
    mp.set_property_number("speed", saved_speed)
    mp.set_property("keep-open", saved_keep_open)
    mp.commandv("seek", 0, "absolute")
    mp.set_property("pause", "yes")

    msg.info("=== DUMP COMPLETE ===")
end

local function tick()
    if not enabled then return end

    if mp.get_property_bool("eof-reached", false) then
        msg.info("=== EOF ===")
        stop_dump()
        return
    end

    local sub = get_sub()
    local pos = mp.get_property_number("time-pos", 0)

    if current_text == "" and sub ~= "" then
        current_text  = sub
        current_start = pos
    elseif current_text ~= "" and sub ~= "" and sub ~= current_text then
        flush_current()
        current_text  = sub
        current_start = pos
    elseif current_text ~= "" and sub == "" then
        flush_current()
    end
end

-- Ctrl+Shift+Alt+T → toggle VTT dump + auto-translate
local function toggle_dump()
    if enabled then stop_dump(); return end

    -- FIX #5: reset ALL translation state before a new dump.
    -- Original code only called clear_file() which reset OUTPUT but left
    -- last_translate_index/failed_index intact. A second dump would then
    -- open OUTPUT_TRANS in "a" (append) mode and skip entries based on
    -- stale line numbers from the previous dump → corrupted output.
    reset_translate_state()
    write_vtt_header(OUTPUT)        -- fresh source VTT
    write_vtt_header(OUTPUT_TRANS)  -- pre-create; translate_vtt_file will overwrite

    current_text  = ""
    current_start = nil

    saved_speed     = mp.get_property_number("speed", 1)
    saved_keep_open = mp.get_property("keep-open")

    enabled = true

    mp.set_property("keep-open", "yes")
    mp.commandv("seek", 0, "absolute")
    mp.set_property("vid", "no")
    mp.set_property_number("speed", DUMP_SPEED)
    mp.set_property("pause", "no")

    timer = mp.add_periodic_timer(0.02, tick)

    msg.info("=== VTT DUMP x" .. DUMP_SPEED .. " ===")
end

-- ==========================================================
-- SHUTDOWN
-- ==========================================================

mp.register_event("shutdown", function()
    if timer then timer:kill() end
    mp.set_property("vid", "auto")
    mp.set_property_number("speed", 1)
end)

-- ==========================================================
-- KEY BINDINGS
-- ==========================================================

mp.add_key_binding("t",                "translate_osd",         guarded(translate_osd))
mp.add_key_binding("Ctrl+Shift+t",     "realtime_translate",    guarded(toggle_realtime))
mp.add_key_binding("Ctrl+Alt+t",       "quick_translate_input", guarded(quick_translate_input))
mp.add_key_binding("Ctrl+Shift+Alt+t", "dump_vtt",              guarded(toggle_dump))
mp.add_key_binding("Ctrl+t",           "set_server_url",        input_server_url)
mp.add_key_binding("Alt+t",            "default_server",        use_default_server)

-- Alt+Shift+T → resume a failed bulk translation
mp.add_key_binding("Alt+Shift+t", "resume_translate", guarded(function()
    msg.info("[RESUME] triggered")
    load_state()

    -- Clear the failure lock so translate_vtt_file retries the stuck line
    if failed_index then
        msg.info("[RESUME] retrying index " .. failed_index)
        failed_index = nil
    else
        msg.info("[RESUME] no failure lock; resuming from index " .. last_translate_index)
    end

    local ok = translate_vtt_file()
    if ok then
        attach_translated_sub()
        show_osd("Resume selesai!")
        msg.info("[RESUME] complete + reattached")
    else
        show_osd("Resume gagal!\nCoba Alt+Shift+T lagi")
        msg.warn("[RESUME] paused at index " .. last_translate_index)
    end
end))

mp.observe_property("pause", "bool", function(_, paused)
    if paused == false then clear_osd() end
end)