-- sets all prices and cooldowns to zero (just for showcase purpose, setting the freeplanting cheat on is probably a better idea)
local memory = require('memory')
memory.start()

local game = require('gameManager')
local defs = require('definitions')
require('utils')

print("Press TAB to exit.")

local frame = 0
local seconds = 0
memory.onUpdate(function()
    frame = frame + 1

    if frame % 60 == 0 then
        frame = 0
        seconds = seconds + 1
        print("One second has passed. (" .. seconds .. ")")

        if seconds >= 3 then
            os.exit(0)
        end
    end

    if memory.isKeyPressed("tab") then
        memory.stopUpdate()
        return
    end
end, 16)

print("Exited. " .. seconds .. " seconds have passed.")

memory.stop()