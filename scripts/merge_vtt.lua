local mp = require "mp"

local function get_tmp_dir()
    if package.config:sub(1,1) == "\\" then
        return os.getenv("TEMP") or os.getenv("TMP") or "C:\\Temp"
    end
    return os.getenv("TMPDIR") or "/tmp"
end

local TMP          = get_tmp_dir()
local OUTPUT       = TMP .. "/sub.vtt"
local OUTPUT_TRANS = TMP .. "/trans.vtt"
local OUTPUT_MERGE = TMP .. "/merged.vtt"

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*all")
    f:close()
    return s
end

local function count_lines(vtt)
    local count = 0

    for line in vtt:gmatch("[^\r\n]+") do
        if line ~= ""
        and line ~= "WEBVTT"
        and not line:match("^%d+$")
        and not line:match("%-%->")
        then
            count = count + 1
        end
    end

    return count
end

local function parse_vtt(vtt)
    local entries = {}

    local idx = nil
    local timecode = nil

    for line in vtt:gmatch("[^\r\n]+") do

        if line:match("^%d+$") then
            idx = line

        elseif line:match("%-%->") then
            timecode = line

        elseif line ~= "" and line ~= "WEBVTT" then
            table.insert(entries, {
                idx = idx,
                time = timecode,
                text = line
            })
        end
    end

    return entries
end

local function merge_vtt()

    local sub_data = read_file(OUTPUT)
    if not sub_data then
        mp.osd_message("sub.vtt tidak ada")
        return
    end

    local trans_data = read_file(OUTPUT_TRANS)
    if not trans_data then
        mp.osd_message("trans.vtt tidak ada")
        return
    end

    local n1 = count_lines(sub_data)
    local n2 = count_lines(trans_data)

    if n1 ~= n2 then
        mp.osd_message(string.format(
            "Jumlah baris beda (%d vs %d)", n1, n2))
        return
    end

    local sub_entries = parse_vtt(sub_data)
    local trans_entries = parse_vtt(trans_data)

    local out = {"WEBVTT", ""}

    for i = 1, #sub_entries do
        table.insert(out, tostring(i))
        table.insert(out, sub_entries[i].time)

        local txt =
            sub_entries[i].text ..
            "\n" ..
            trans_entries[i].text

        table.insert(out, txt)
        table.insert(out, "")
    end

    local f = io.open(OUTPUT_MERGE, "w")
    if not f then
        mp.osd_message("Gagal membuat merged.vtt")
        return
    end

    f:write(table.concat(out, "\n"))
    f:close()

    mp.commandv(
        "sub-add",
        OUTPUT_MERGE,
        "select",
        "Merged"
    )

    mp.osd_message("Merged subtitle attached")
end

mp.add_key_binding("Ctrl+m", "merge-vtt", merge_vtt)