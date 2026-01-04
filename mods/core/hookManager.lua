local memory = require("memory")

local t = {
    hooks = {}
}

local function exCode(code, start, offset)
    for _, byte in ipairs(code) do
        memory.writeByte(start + offset, byte)
        offset = offset + 1
    end
    return offset
end

-- Hooks a function and returns true if successful
---@param funcAddr integer
---@param instrSize integer >= 5
---@param caveSize? integer
---@param customCode? integer[]
---@param customCodeFirst? boolean -- true = custom code first, false = original code, then custom
---@param jumpBackOffset? integer -- unstable? keep to 0
function t.installHook(funcAddr, instrSize, caveSize, customCode, customCodeFirst, jumpBackOffset)
    customCodeFirst = customCodeFirst or false
    jumpBackOffset = jumpBackOffset or 0

    if instrSize < 5 then
        print("error: instrSize must be >= 5")
        return false
    end

    caveSize = caveSize or 128

    -- save original bytes
    local originalBytes = {}
    for i = 0, instrSize - 1 do
        originalBytes[i] = memory.readByte(funcAddr + i)
    end

    -- allocate cave
    local cave = memory.allocateEx(caveSize)
    if not cave or cave == 0 then -- (TODO: i forgot what allocateEx returns when it fails)
        print("Error: unable to allocate memory")
        return false
    end

    -- layout: cave+0 = counter, cave+1 = code
    local codeStart = cave + 1
    local offset = 0

    -- init counter
    memory.writeByte(cave, 0)

    -- inc counter
    memory.writeByte(codeStart + offset, 0xFE)
    offset = offset + 1
    memory.writeByte(codeStart + offset, 0x05)
    offset = offset + 1
    memory.writeInt(codeStart + offset, cave)
    offset = offset + 4

    local thereIsCustomCode = customCode and #customCode > 0
    -- custom code
    if thereIsCustomCode and customCodeFirst then
        offset = exCode(customCode, codeStart, offset)
    end

    -- original instruction inside the cave
    if originalBytes[0] == 0xE8 then -- relative call adjustment
        memory.writeByte(codeStart + offset, 0xE8)
        offset = offset + 1

        local originalOffset = memory.readInt(funcAddr + 1)
        local targetAddr = funcAddr + 5 + originalOffset

        local newOffset = targetAddr - (codeStart + offset + 5)

        memory.writeInt(codeStart + offset, newOffset + 1) -- "+1" because code starts at cave+1
        offset = offset + 4
    else
        for i = 0, instrSize - 1 do
            memory.writeByte(codeStart + offset, originalBytes[i])
            offset = offset + 1
        end
    end

    if thereIsCustomCode and not customCodeFirst then
        offset = exCode(customCode, codeStart, offset)
    end

    -- jmp back
    local retAddr = funcAddr + instrSize
    local jmpOffset = retAddr - (codeStart + offset + 5)
    memory.writeByte(codeStart + offset, 0xE9)
    offset = offset + 1
    memory.writeInt(codeStart + offset, jmpOffset + jumpBackOffset)

    -- install hook
    local hookOffset = codeStart - (funcAddr + 5)
    memory.writeByte(funcAddr, 0xE9)
    memory.writeInt(funcAddr + 1, hookOffset)

    -- nop rest
    for i = 5, instrSize - 1 do
        memory.writeByte(funcAddr + i, 0x90)
    end

    -- save hook info
    t.hooks[funcAddr] = {
        cave = cave,
        codeStart = codeStart,
        originalBytes = originalBytes,
        instrSize = instrSize,
        counterAddr = cave
    }

    return true
end

function t.removeHook(funcAddr)
    local hook = t.hooks[funcAddr]
    if not hook then return false end

    -- restore original bytes
    for i = 0, hook.instrSize - 1 do
        memory.writeByte(funcAddr + i, hook.originalBytes[i])
    end

    -- free memory
    memory.freeEx(hook.cave)

    t.hooks[funcAddr] = nil
    return true
end

function t.getCallCount(funcAddr)
    local hook = t.hooks[funcAddr]
    if not hook then return 0 end
    return memory.readByte(hook.counterAddr)
end

function t.resetCallCount(funcAddr)
    local hook = t.hooks[funcAddr]
    if hook then
        memory.writeByte(hook.counterAddr, 0)
    end
end

function t.removeAllHooks()
    for funcAddr, _ in pairs(t.hooks) do
        t.removeHook(funcAddr)
    end
end

return t

-- original code tested:
--[[

local game = require("gameManager")
local memory = require("memory")
memory.start()

local function set_call_near_relative(func, bytesize, target)
    if bytesize < 5 then return end
    -- E8 XX XX XX XX
    local offset = target - (func + 5)

    memory.writeByte(func, 0xE8)
    memory.writeInt(func + 1, offset)

    -- fill rest with nop
    for i = 5, bytesize - 1 do
        memory.writeByte(func + i, 0x90)
    end
end

local func = 0x40D120 + 9 -- 0x40D129 (the first instruction with 6 bytes)
local cave = 0x651200
-- local cave = memory.allocateEx(64)

-- 8D B5 AC 00 00 00 - lea esi, [ebp+000000AC]
local original = {
    byte1 = memory.readByte(func), -- 8D
    byte2to6 = memory.readInt(func + 1), -- B5 AC 00 00
    byte6 = memory.readByte(func + 5) -- 00
}

-- init counter to 0 (once)
memory.writeByte(cave, 0)

-- custom code (increment)
memory.writeShort(cave + 1, 0x05FE) -- FE 05 XXXXXXXX - INC BYTE PTR
memory.writeInt(cave + 3, cave)

-- pushad
memory.writeByte(cave + 7, 0x90)--0x60)

-- copy instruction to the cave
memory.writeByte(cave + 8, original.byte1)
memory.writeInt(cave + 9, original.byte2to6)
memory.writeByte(cave + 13, original.byte6)

-- popad
memory.writeByte(cave + 14, 0x90)--0x61)

-- jump back
local jmp = cave + 15 -- AFTER popad
local ret = func + 6 -- after func
local jmp_offset = ret - (jmp + 5) -- E9 XX XX XX XX

memory.writeByte(jmp, 0xE9)
memory.writeInt(jmp + 1, jmp_offset)
memory.writeByte(jmp + 5, 0x90) --! no idea if this is needed

-- replace instruction with jump to cave
set_call_near_relative(func, 6, cave + 1)

memory.onUpdate(function()
    if memory.readByte(cave) == 0x1 then
        print("Function called")

        memory.writeByte(cave, 0x0)

        memory.stopUpdate()
        return
    end
end, 16)

memory.stop()

]]