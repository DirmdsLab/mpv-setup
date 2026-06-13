-- color_profiles.lua

local profiles = {
    ["!"] = { name = "Natural (Default)", contrast = 0, brightness = 0, gamma = 0, saturation = 0 },
    ["%"] = { name = "Color Boost", contrast = 0, brightness = 0, gamma = 0, saturation = 70 },
}

local function apply_profile(symbol)
    local p = profiles[symbol]
    if not p then
        mp.osd_message("profiles not found" .. symbol)
        return
    end
    mp.set_property_number("contrast", p.contrast)
    mp.set_property_number("brightness", p.brightness)
    mp.set_property_number("gamma", p.gamma)
    mp.set_property_number("saturation", p.saturation)
    mp.osd_message("profiles warna: " .. p.name)
end

mp.add_key_binding("Ctrl+Shift+!", "profile_1", function() apply_profile("!") end)
mp.add_key_binding("Ctrl+y", "profile_5", function() apply_profile("%") end)
