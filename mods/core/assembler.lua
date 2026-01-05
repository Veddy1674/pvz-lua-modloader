-- convert numbers to bytes little endian
local function toBytesLE(num, size)
    local bytes = {}
    for i = 1, size do
        bytes[i] = num & 0xFF
        num = math.floor(num / 256)
    end
    return bytes
end

local function toDwordLE(num)
    return toBytesLE(num, 4)
end

local function toWordLE(num)
    return toBytesLE(num, 2)
end

-- immediate-value instructions

function MOV_EAX(imm)
    return {0xB8, table.unpack(toDwordLE(imm))}
end

function MOV_EBX(imm)
    return {0xBB, table.unpack(toDwordLE(imm))}
end

function MOV_ECX(imm)
    return {0xB9, table.unpack(toDwordLE(imm))}
end

function MOV_EDX(imm)
    return {0xBA, table.unpack(toDwordLE(imm))}
end

function MOV_ESI(imm)
    return {0xBE, table.unpack(toDwordLE(imm))}
end

function MOV_EDI(imm)
    return {0xBF, table.unpack(toDwordLE(imm))}
end

-- MOVs

function MOV_EAX_EBX()
    return {0x89, 0xD8}
end

function MOV_EBX_EAX()
    return {0x89, 0xC3}
end

-- PUSHes and POPs

function PUSH_EAX()
    return {0x50}
end

function PUSH_EBX()
    return {0x53}
end

function PUSH_ECX()
    return {0x51}
end

function POP_EAX()
    return {0x58}
end

function POP_EBX()
    return {0x5B}
end

function POP_ECX()
    return {0x59}
end

-- returns

function RET()
    return {0xC3}
end

function RETN(imm)
    return {0xC2, table.unpack(toWordLE(imm))}
end

-- NOP
function NOP()
    return {0x90}
end

-- CALL (relative)
function CALL_REL(offset)
    return {0xE8, table.unpack(toDwordLE(offset))}
end

-- JMP (relative)
function JMP_REL(offset)
    return {0xE9, table.unpack(toDwordLE(offset))}
end

-- CMPs

function CMP_EAX(imm)
    return {0x3D, table.unpack(toDwordLE(imm))}
end

function CMP_EBX(imm)
    return {0x81, 0xFB, table.unpack(toDwordLE(imm))}
end

function CMP_ECX(imm)
    return {0x81, 0xF9, table.unpack(toDwordLE(imm))}
end

function CMP_EDX(imm)
    return {0x81, 0xFA, table.unpack(toDwordLE(imm))}
end

function CMP_ESI(imm)
    return {0x81, 0xFE, table.unpack(toDwordLE(imm))}
end

function CMP_EDI(imm)
    return {0x81, 0xFF, table.unpack(toDwordLE(imm))}
end

-- CMPs immediate

function CMP_EAX_SHORT(imm)
    return {0x83, 0xF8, imm & 0xFF}
end

function CMP_EBX_SHORT(imm)
    return {0x83, 0xFB, imm & 0xFF}
end

function CMP_ECX_SHORT(imm)
    return {0x83, 0xF9, imm & 0xFF}
end

function CMP_EDX_SHORT(imm)
    return {0x83, 0xFA, imm & 0xFF}
end

-- CMP register to register

function CMP_EAX_EBX()
    return {0x39, 0xD8}
end

function CMP_EBX_EAX()
    return {0x39, 0xC3}
end

function CMP_EAX_ECX()
    return {0x39, 0xC8}
end

function CMP_ECX_EAX()
    return {0x39, 0xC1}
end

-- Conditional jumps (short, 1 byte offset)

function JE(offset)  -- Jump if Equal (ZF=1)
    return {0x74, offset & 0xFF}
end

function JNE(offset) -- Jump if Not Equal (ZF=0)
    return {0x75, offset & 0xFF}
end

function JL(offset)  -- Jump if Less (SF != OF)
    return {0x7C, offset & 0xFF}
end

function JLE(offset) -- Jump if Less or Equal (ZF=1 or SF != OF)
    return {0x7E, offset & 0xFF}
end

function JG(offset)  -- Jump if Greater (ZF=0 and SF=OF)
    return {0x7F, offset & 0xFF}
end

function JGE(offset) -- Jump if Greater or Equal (SF=OF)
    return {0x7D, offset & 0xFF}
end

-- others:

function MOV_ECX_DWORD_PTR_ESI(offset)
    -- MOV ECX, DWORD PTR [ESI+offset]
    return {0x8B, 0x8E, table.unpack(toDwordLE(offset))}
end

---@diagnostic disable-next-line: lowercase-global
function flatten(tbl)
    local result = {}
    for _, v in ipairs(tbl) do
        if type(v) == "table" then
            for _, byte in ipairs(v) do
                table.insert(result, byte)
            end
        else
            table.insert(result, v)
        end
    end
    return result
end

-- random example
-- local code = flatten({
--     MOV_EBX(41),
--     MOV_EAX(0x12345678),
--     PUSH_EAX(),
--     CALL_REL(0x1000),
--     RET()
-- })