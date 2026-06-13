-- sub seek

local mp = require 'mp'

local function seek_prev_sub()
    mp.command("sub-seek -1")
end

-- keybind: n
mp.add_key_binding("n", "subtitle_seek_prev", seek_prev_sub)
