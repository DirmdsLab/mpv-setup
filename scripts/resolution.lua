-- Resolution change + No Video

local mp = require 'mp'

local resolutions = {
    { name = "No Video (Audio Only)", no_video = true },

    { name = "Default (Original)", vf = "" },

    { name = "── NO CROP ──", header = true },

    { name = "4K (3840x2160)", vf = "scale=3840:2160:force_original_aspect_ratio=decrease" },
    { name = "2K (2560x1440)", vf = "scale=2560:1440:force_original_aspect_ratio=decrease" },
    { name = "1080p", vf = "scale=1920:1080:force_original_aspect_ratio=decrease" },
    { name = "720p",  vf = "scale=1280:720:force_original_aspect_ratio=decrease" },
    { name = "480p",  vf = "scale=854:480:force_original_aspect_ratio=decrease" },
    { name = "360p",  vf = "scale=640:360:force_original_aspect_ratio=decrease" },
    { name = "144p",  vf = "scale=256:144:force_original_aspect_ratio=decrease" },

    { name = "── CROP ──", header = true },

    { name = "4K (Crop)", vf = "scale=3840:2160:force_original_aspect_ratio=increase,crop=3840:2160" },
    { name = "2K (Crop)", vf = "scale=2560:1440:force_original_aspect_ratio=increase,crop=2560:1440" },
    { name = "1080p (Crop)", vf = "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" },
    { name = "720p (Crop)",  vf = "scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720" },
    { name = "480p (Crop)",  vf = "scale=854:480:force_original_aspect_ratio=increase,crop=854:480" },
    { name = "360p (Crop)",  vf = "scale=640:360:force_original_aspect_ratio=increase,crop=640:360" },
    { name = "144p (Crop)",  vf = "scale=256:144:force_original_aspect_ratio=increase,crop=256:144" },
}

local menu_open = false
local selected = 1

local function is_selectable(i)
    return not resolutions[i].header
end

local function move_selection(dir)
    repeat
        selected = selected + dir
        if selected < 1 then selected = #resolutions end
        if selected > #resolutions then selected = 1 end
    until is_selectable(selected)
end

local function render_menu()
    local text = "Resolution Menu\n\n"
    for i, r in ipairs(resolutions) do
        if r.header then
            text = text .. r.name .. "\n"
        elseif i == selected then
            text = text .. "▶ " .. r.name .. "\n"
        else
            text = text .. "  " .. r.name .. "\n"
        end
    end
    text = text .. "\n↑ ↓ Select | Enter OK | Esc"
    mp.osd_message(text, 60)
end

local function close_menu()
    menu_open = false
    mp.osd_message("")
    mp.remove_key_binding("res_up")
    mp.remove_key_binding("res_down")
    mp.remove_key_binding("res_enter")
    mp.remove_key_binding("res_esc")
end

local function apply_resolution()
    local item = resolutions[selected]

    -- reset semua dulu
    mp.set_property("vf", "")
    mp.set_property("vid", "auto")

    -- mode no video
    if item.no_video then
        mp.set_property("vid", "no")
        mp.osd_message("Video OFF (Audio Only)", 2)
        close_menu()
        return
    end

    -- apply filter kalau ada
    if item.vf ~= "" then
        mp.set_property("vf", item.vf)
    end

    mp.osd_message("Resolution set: " .. item.name, 2)
    close_menu()
end

local function open_menu()
    if menu_open then
        close_menu()
        return
    end

    menu_open = true

    selected = 1
    while not is_selectable(selected) do
        selected = selected + 1
    end

    render_menu()

    mp.add_forced_key_binding("UP", "res_up", function()
        move_selection(-1)
        render_menu()
    end)

    mp.add_forced_key_binding("DOWN", "res_down", function()
        move_selection(1)
        render_menu()
    end)

    mp.add_forced_key_binding("ENTER", "res_enter", apply_resolution)
    mp.add_forced_key_binding("ESC", "res_esc", close_menu)
end

-- Ctrl + R buka menu
mp.add_key_binding("Ctrl+r", "resolution_menu", open_menu)