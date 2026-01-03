local game = require("gameManager")
local memory = require("memory")
memory.start()

local hooker = require("hookManager")

-- 1. choose a function to hook
-- 2. view it in cheat engine or HxD, find an instruction that is 5 or more bytes long
-- 3. there you have the first two arguments, the third is the allocated memory size, "nil" is the default 128
-- 4. the fourth argument is the custom code to execute, an array of bytes, can be nil to just detect calls

local func = Callbacks.put_plant + 9
if not hooker.installHook(func, 6, 64) then return end

local old = 0
memory.onUpdate(function()
    local new = hooker.getCallCount(func)

    if new ~= old then
        print("Function called - " .. new)

        if new > 5 then
            memory.stopUpdate()
            return
        end
        old = new
    end
end, 16)

hooker.removeHook(func)
memory.stop()