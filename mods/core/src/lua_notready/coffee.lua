local game, memory = require("core")
memory.start()

-- Decompiled (https://github.com/ruslan831/PlantsVsZombies-decompilation/blob/master/Lawn/Board.cpp) at line 2743

if arg[1] and arg[1] == "disable" then
    memory.writeByte(0x40E137, 0x74) -- je (jump if equal/zero)
else
    memory.writeByte(0x40E137, 0x75) -- jne (jump if not equal/zero)
end
-- inverts logic: you can plant it on normal awake plants and not asleep plants!

memory.stop()