-- Wrapper for "mem.dll"
---@class Memory
-- Initializes data (pointer chains) to view & edit the game's memory
---@field start fun(): boolean
-- Closes the game's process and frees memory, not mandatory but good practice to do
---@field stop fun()
-- Returns a value from the game's memory at the specified address or pointer chain
---@field readMemory fun(addressOrTable: integer|integer[]): integer|nil
-- Writes <b>value</b> (integer or array of bytes) to the game's memory at the specified address or pointer chain
---@field writeMemory fun(addressOrTable: integer|integer[], value: integer|integer[]): boolean
-- Reads a single byte from the game's memory
---@field readByte fun(addressOrTable: integer|integer[]): integer
-- Writes a single byte to the game's memory
---@field writeByte fun(addressOrTable: integer|integer[], value: integer): boolean
-- Reads 2 bytes from the game's memory
---@field readShort fun(addressOrTable: integer|integer[]): integer
-- Writes 2 bytes to the game's memory
---@field writeShort fun(addressOrTable: integer|integer[], value: integer): boolean
-- Reads 4 bytes from the game's memory
---@field readInt fun(addressOrTable: integer|integer[]): integer
-- Writes 4 bytes to the game's memory
---@field writeInt fun(addressOrTable: integer|integer[], value: integer): boolean
-- Reads 4 bytes as a float from the game's memory
---@field readFloat fun(addressOrTable: integer|integer[]): number
-- Writes 4 bytes as a float to the game's memory
---@field writeFloat fun(addressOrTable: integer|integer[], value: number): boolean
-- Runs a <b>function</b> every <b>ms</b> milliseconds (sync, default 16ms)
---@field onUpdate fun(function: function, ms?: integer)
-- Stops the <b>onUpdate</b> loop (ignored if onUpdate was not called)
---@field stopUpdate fun()
-- Sleeps for <b>ms</b> milliseconds
---@field sleep fun(ms: integer)
---@field listeners table
-- A lua-sided event system:<br>
--[[
```lua
memory.addListener(game._sun(), function(prev, cur)
    if prev == nil then return end -- ignore first time
    print("Sun from " .. prev .. " to " .. cur)
end)

memory.onUpdate(function()
    memory.processListeners()
end)
```]]
---@field addListener fun(address: integer|integer[], fun: function)
-- Removes a listener
---@field removeListener fun(address: integer|integer[])
-- Runs all the event listeners, usually used in a loop (preferably <b>onUpdate</b>)
---@field processListeners fun()
-- Returns whether <b>key</b> is currently pressed. If <b>foreground</b> is true (default),<br> it checks that the window is active to avoid conflicts
---@field isKeyPressed fun(key: string, foreground?: boolean): boolean
-- Clears the current assembly buffer and call position list
---@field asm_init fun()
-- Adds a single byte to the assembly buffer
---@field asm_add_byte fun(value: integer)
-- Adds a 16-bit word to the assembly buffer
---@field asm_add_word fun(value: integer)
-- Adds a 32-bit dword to the assembly buffer
---@field asm_add_dword fun(value: integer)
-- Adds the instruction: PUSH imm8 (push immediate 8-bit value)
---@field asm_push_byte fun(value: integer)
-- Adds the instruction: PUSH imm32 (push immediate 32-bit value)
---@field asm_push_dword fun(value: integer)
-- Adds the instruction: MOV reg, imm32 (move immediate value into register)
---@field asm_mov_reg_imm fun(reg: integer, value: integer)
-- Adds the instruction: MOV reg, [imm32] (load from absolute memory address)
---@field asm_mov_dword_ptr_reg fun(reg: integer, address: integer)
-- Adds the instruction: MOV reg, [reg + imm32] (load from register base + displacement)
---@field asm_mov_dword_ptr_reg_add fun(reg: integer, offset: integer)
-- Adds the instruction: PUSH reg (push register onto stack)
---@field asm_push_reg fun(reg: integer)
-- Adds the instruction: POP reg (pop value from stack into register)
---@field asm_pop_reg fun(reg: integer)
-- Adds the instruction: MOV reg_to, reg_from (copy between registers)
---@field asm_mov_reg_reg fun(toReg: integer, fromReg: integer)
-- Adds a list of raw bytes to the assembly buffer
---@field asm_add_list fun(bytes: integer[])
-- Adds a CALL instruction to absolute address (will be patched to relative at injection time)
---@field asm_call fun(address: integer)
-- Adds a RET instruction (add byte 0xC3)
---@field asm_ret fun()
-- Executes the assembled code in the game's memory and returns EAX value
---@field asm_code_inject fun(): integer|nil
-- Constants
---@field EAX integer 0
---@field ECX integer 1
---@field EDX integer 2
---@field EBX integer 3
---@field ESP integer 4
---@field EBP integer 5
---@field ESI integer 6
---@field EDI integer 7

-- utils
---@diagnostic disable-next-line: lowercase-global
printx = function(n)
    print(n and string.format("0x%x", n) or "nil")
end

package.cpath = package.cpath .. ";.\\core\\?.dll"

---@type Memory
local memory = require("mem") -- mem.dll

local orig_stop = memory.stop
memory.stop = function()
    memory.stopUpdate()
    return orig_stop()
end

-- events (TODO: rewise)
memory.listeners = {} -- addr -> {val=..., cb=...}

local function check(addr, listener)
    local new_val = memory.readInt(addr)

    if new_val ~= listener.val then
        listener.cb(listener.val, new_val)
        listener.val = new_val
    end
end

function memory.addListener(addr, fun)
    local val = memory.readInt(addr)
    memory.listeners[addr] = {val = val, cb = fun} -- if nil, it will be called on first check

    fun(nil, val)
end

function memory.processListeners()
    for addr, listener in pairs(memory.listeners) do
        check(addr, listener)
    end
end

return memory