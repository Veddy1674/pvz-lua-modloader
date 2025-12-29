local memory = require('memory')
memory.start()

local game = require('gameManager')
local defs = require('definitions')
require('utils')

local function writeBytesManual(address, bytes)
    -- 
    for i = 1, #bytes do
        memory.writeByte({address + i - 1}, bytes[i])
    end
end

local function enableHomingProjectiles()
    -- 
    writeBytesManual(0x00467683, {0xE9, 0x40, 0x00, 0x00, 0x00})
    
    -- 
    memory.writeByte({0x00464A60}, 0x90)
    memory.writeByte({0x00464A61}, 0x90)
    
    memory.writeByte({0x00467384}, 0x90)
    memory.writeByte({0x00467385}, 0x90)
    
    -- Patch 3: nop out le je (6 nop each)
    local nop_addresses = {
        0x00467352, 0x00467353, 0x00467354, 0x00467355, 0x00467356, 0x00467357,
        0x0046735B, 0x0046735C, 0x0046735D, 0x0046735E, 0x0046735F, 0x00467360,
        0x004672D0, 0x004672D1, 0x004672D2, 0x004672D3, 0x004672D4, 0x004672D5,
        0x004672D9, 0x004672DA, 0x004672DB, 0x004672DC, 0x004672DD, 0x004672DE,
        0x004672E2, 0x004672E3, 0x004672E4, 0x004672E5, 0x004672E6, 0x004672E7,
        0x004672EB, 0x004672EC, 0x004672ED, 0x004672EE, 0x004672EF, 0x004672F0
    }
    
    for _, addr in ipairs(nop_addresses) do
        memory.writeByte({addr}, 0x90)
    end
    
    -- 
    writeBytesManual(0x004672F4, {0xE9, 0x56, 0x00, 0x00, 0x00})
    
    writeBytesManual(0x0045EB16, {0xE9, 0x0D, 0x00, 0x00, 0x00})
    
    print("Homing projectiles enabled!")
    return true
end

enableHomingProjectiles()

memory.stop()