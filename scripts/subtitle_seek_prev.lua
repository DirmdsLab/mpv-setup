-- sub seek

local mp = require 'mp'

local function seek_prev_sub()
    mp.command("sub-seek -1")
end

local function seek_next_sub()
    mp.command("sub-seek 1")
end

mp.add_key_binding("n", "subtitle_seek_prev", seek_prev_sub)

mp.add_key_binding("N", "subtitle_seek_next", seek_next_sub)