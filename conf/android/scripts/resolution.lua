-- Resolution change + No Video
-- Press R to cycle

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

local current = 0

local function cycle_resolution()
    repeat
        current = current + 1

        if current > #resolutions then
            current = 1
        end
    until not resolutions[current].header

    local item = resolutions[current]

    -- reset
    mp.set_property("vf", "")
    mp.set_property("vid", "auto")

    if item.no_video then
        mp.set_property("vid", "no")
        mp.osd_message("Resolution: " .. item.name, 2)
        return
    end

    if item.vf ~= "" then
        mp.set_property("vf", item.vf)
    end

    mp.osd_message("Resolution: " .. item.name, 2)
end

mp.add_key_binding("0x10003", "cycle_resolution", cycle_resolution)
