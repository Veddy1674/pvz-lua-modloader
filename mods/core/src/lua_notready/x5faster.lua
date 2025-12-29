local game, memory = require("core")
memory.start()

-- this script is done but so simple I decided not to include in the examples
if Contains(arg, "disable") then
    game.frameDuration(10) -- default speed
    defs.setAutoCollector(memory, false)
else -- Enable
    game.frameDuration(2) -- x : "x4 speed" = 10 : 1
    defs.setAutoCollector(memory, true)
end

memory.stop()
