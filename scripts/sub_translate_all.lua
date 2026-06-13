local mp = require 'mp'
local utils = require 'mp.utils'
local input = require 'mp.input'

local server_url = ""

-- ==========================================================
-- OSD
-- ==========================================================

local function show_osd(text)

    print("[SUB-TRANSLATE] "..text)

    local w = mp.get_property_number("dwidth",1920)
    local h = mp.get_property_number("dheight",1080)

    mp.set_osd_ass(
        w,
        h,
        "{\\fs40\\an7\\pos(20,120)}"..text
    )

    mp.add_timeout(5,function()
        mp.set_osd_ass(w,h,"")
    end)

end
-- ==========================================================
-- EXTRACT SUBTITLE FROM TRACK
-- ==========================================================

local function extract_subtitle()

    local video = mp.get_property("path")
    local sid = mp.get_property_number("sid")

    if not video then
        show_osd("No video loaded")
        return nil
    end

    if not sid then
        show_osd("No subtitle selected")
        return nil
    end

    local temp = "/tmp/mpv_extract_sub.srt"

    show_osd("Extracting subtitle...")

    local res = utils.subprocess({
        args = {
            "ffmpeg",
            "-y",
            "-loglevel","error",
            "-i", video,
            "-map", "0:s:" .. (sid - 1),
            temp
        }
    })

    if res.status ~= 0 then
        show_osd("Subtitle extract failed")
        return nil
    end

    return temp
end

-- ==========================================================
-- PARSE SRT
-- ==========================================================

local function parse_srt(path)

    local f = io.open(path,"r")
    if not f then return nil end

    local content = f:read("*all")
    f:close()

    local subs = {}

    for block in content:gmatch("(.-)\n\n") do

        local num,time,text = block:match("(%d+)\n(.-)\n(.+)")

        if num and time and text then

            text = text:gsub("\n"," ")
            text = text:gsub("<.->","")

            table.insert(subs,{
                text = text,
                time = time
            })
        end
    end

    return subs
end

-- ==========================================================
-- SEND TO SERVER
-- ==========================================================

local function send_to_server(subs)

    local json = utils.format_json({
        subs = subs
    })

    local res = utils.subprocess({
        args = {
            "curl",
            "-s",
            "-X","POST",
            server_url .. "/translate_sub",
            "-H","Content-Type: application/json",
            "-d",json
        }
    })

    if res.status ~= 0 then
        return nil
    end

    return res.stdout
end

-- ==========================================================
-- SAVE VTT
-- ==========================================================

local function save_vtt(vtt)

    local file = "/tmp/mpv_translated.vtt"

    local f = io.open(file,"w")
    f:write(vtt)
    f:close()

    return file
end

-- ==========================================================
-- MAIN TRANSLATE
-- ==========================================================

local function translate_all()

    if server_url == "" then
        show_osd("Set server first (Press D)")
        return
    end

    local subfile = extract_subtitle()

    if not subfile then
        return
    end

    show_osd("Parsing subtitle...")

    local subs = parse_srt(subfile)

    if not subs then
        show_osd("Parse failed")
        return
    end

    show_osd("Sending "..#subs.." lines to server...")

    local vtt = send_to_server(subs)

    if not vtt then
        show_osd("Server error")
        return
    end

    local file = save_vtt(vtt)

    mp.commandv("sub-add",file,"select")

    show_osd("Translated subtitle loaded")
end

-- ==========================================================
-- INPUT SERVER
-- ==========================================================

local function set_server()

    input.get({
        prompt = "Server URL: ",
        submit = function(text)

            if text and text ~= "" then
                server_url = text
                show_osd("Server set:\n"..server_url)
            else
                show_osd("Invalid URL")
            end

        end
    })
end

-- ==========================================================
-- KEYBIND
-- ==========================================================

mp.add_key_binding("D","set_server",set_server)
mp.add_key_binding("Ctrl+Alt+t","translate_all",translate_all)