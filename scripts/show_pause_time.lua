-- Pause OSD

function show_pause_time()
    local paused = mp.get_property_native("pause")
    if paused then
        local time_now = mp.get_property_number("time-pos") or 0
        local duration = mp.get_property_number("duration") or 0
        local title = mp.get_property("media-title") or "Tidak diketahui"

        local time_now_str = mp.get_property_osd("time-pos") or "0:00"
        local duration_str = mp.get_property_osd("duration") or "0:00"

        local remain = math.max(duration - time_now, 0)
        local r_min = math.floor(remain / 60)
        local r_sec = math.floor(remain % 60)

        local remain_str = string.format("-%d:%02d", r_min, r_sec)

        local msg = string.format("%s\n%s / %s  |  %s", 
                                  title, time_now_str, duration_str, remain_str)

        mp.osd_message(msg, 2)
    end
end

mp.observe_property("pause", "bool", function(name, value)
    if value == true then
        show_pause_time()
    end
end)
