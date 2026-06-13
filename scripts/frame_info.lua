-- frame_info.lua

local function print_frame_info()
    local frame = mp.get_property_number("estimated-frame-number")
    if frame then
        print("Frame:", frame)
    else
        print("Frame: (unknown)")
    end
end

mp.add_key_binding(".", "next-frame-info", function()
    mp.command("frame-step")
    print_frame_info()
end)

mp.add_key_binding(",", "prev-frame-info", function()
    mp.command("frame-back-step")
    print_frame_info()
end)
