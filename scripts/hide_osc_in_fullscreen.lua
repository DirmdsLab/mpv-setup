-- fullscreen

mp.observe_property("fullscreen", "bool", function(name, val)
    if val == true then
        mp.command("script-message osc-visibility never")
    else
        mp.command("script-message osc-visibility auto")
    end
end)
