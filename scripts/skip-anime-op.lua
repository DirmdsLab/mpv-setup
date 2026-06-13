-- Skip anime op 85 S

local function skip(seconds)
    local current_time = mp.get_property_number("time-pos", 0)
    mp.set_property_number("time-pos", current_time + seconds)
    local sign = seconds > 0 and ">>" or "<<"
    mp.osd_message(string.format("%s Skipped %d seconds", sign, math.abs(seconds)), 1)
end

mp.add_forced_key_binding("ctrl+d", "skip_forward_85", function()
    skip(85)
end)

mp.add_forced_key_binding("ctrl+a", "skip_backward_85", function()
    skip(-85)
end)
