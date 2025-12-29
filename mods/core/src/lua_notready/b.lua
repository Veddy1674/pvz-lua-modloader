local game, memory = require("core")
memory.start()

-- i forgot what this does
memory.writeByte(0x464E9F+2, 0x02)

memory.stop()