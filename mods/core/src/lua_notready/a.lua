local game, memory = require("core")
memory.start()

local function patch(addr, hex)
    local i = 1
    for h in hex:gmatch("%S+") do
        memory.writeByte({addr + i - 1}, tonumber(h, 16))
        i = i + 1
    end
end
local MOV = game.patch_MOV

-- CHANGES SQUASH ZOMBIE HEAD IN SOMETHING

-- originally: 523c6e: MOV EBX, 0A (0B to disable)
patch(0x523C6E, MOV("EBX", 0x13))
game.placeZombieNaturally(0,30)

-- 0x0B = squash
-- 0x0A = cherry bomb
-- 0x0C = doom shroom
-- 0x08 = lawnmower
-- 0x09 = "PLANT!" big red text
-- 0x10 = tall nut
-- 0x11 = fume shroom
-- 0x12 = puff shroom
-- 0x13 = hypno shroom

-- Note: This applies for the next zombies spawning:
-- If you spawn a squash zombie, run this code and then spawn another, you will have squash and cherry bomb zombies separately

memory.stop()