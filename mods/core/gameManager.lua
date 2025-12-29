local memory = require("memory")
local defs = require("definitions")

---@class GameManager
local game = {}

function game._scene()
    return {Offsets.lawn, Offsets.board, Offsets.scene}
end

-- Returns the current scene as an integer 0 to 5
function game.scene(v)
    if v ~= nil then
        memory.writeMemory(game._scene(), v)
        return game.scene(nil)
    else
        return memory.readMemory(game._scene())
    end
end

-- The coordinate system I'm using treats rows as the X axis and columns as the Y axis.
-- In the original C++ pvztoolkit the method below is named 'getRowCount' instead: (github.com/lmintlcx/pvztoolkit/blob/master/src/pvz.cpp)
-- For this reason in .placePlant and such functions, I'm using x and y instead of row and col for it to be clear.

-- Returns the number of columns in the current scene (6 for pool, 5 others)
function game.getColCount() -- (Y axis)
    local scene = game.scene()
    return (scene == Scene.pool_day or scene == Scene.pool_night) and 6 or 5
end

-- Returns wheter x and y are invalid in the current scene
local function isInvalidPos(x, y)
    return (x < 0 or x > 8) or (y < 0 or y >= game.getColCount())
end

function game._frameDuration()
    return {Offsets.lawn, Offsets.frame_duration}
end

-- Default 10
function game.frameDuration(v)
    if v ~= nil then
        memory.writeMemory(game._frameDuration(), v)
        return game.frameDuration(nil)
    else
        return memory.readMemory(game._frameDuration())
    end
end

function game.gameSpeed(v) -- alias
    -- 1 = 10
    -- 2 = 5
    return game.frameDuration(math.clamp(math.floor(10 / v), 1, 10))
end

function game.getGameUI()
    return memory.readMemory({Offsets.lawn, Offsets.game_ui})
end

function game.getLawnMowersCount() -- ui 2 or 3
    return memory.readMemory({Offsets.lawn, Offsets.board, Offsets.lawn_mower_count})
end

function game._blockMainLoop(enable)
    -- block_main_loop = {address, {new_bytes}, {old_bytes}}
    local blockInfo = Callbacks.block_main_loop
    local address = blockInfo[1]
    local enableBytes = blockInfo[2] -- {0xfe}
    local disableBytes = blockInfo[3] -- {0xc8}

    enable = (enable == nil) and true or enable
    if enable then
        -- 0xFE
        memory.writeMemory(address, enableBytes[1])
    else
        -- 0xC8 restore
        memory.writeMemory(address, disableBytes[1])
    end
end

local function sleepMs(ms)
    memory.sleep(ms)
end

local old_asm_code_inject = memory.asm_code_inject
memory.asm_code_inject = function()
    -- making asm injection safer
    game._blockMainLoop(true)

    local frameDuration = game.frameDuration()
    sleepMs(frameDuration * 2)

    local result = old_asm_code_inject()

    game._blockMainLoop(false)

    return result
end

-- Aliases
local EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI =
    memory.EAX, memory.ECX, memory.EDX, memory.EBX, memory.ESP, memory.EBP, memory.ESI, memory.EDI

local OPCODES = {
    EAX = 0xB8, EBX = 0xBB,
    ECX = 0xB9, EDX = 0xBA,
    ESI = 0xBE, EDI = 0xBF,
    EBP = 0xBD, ESP = 0xBC
}

-- mov_reg_imm
function game.patch_MOV(reg, value)
    local op = OPCODES[reg]
    if not op then return nil end

    -- little endian
    local b1 = value % 256
    local b2 = math.floor(value / 256) % 256
    local b3 = math.floor(value / 65536) % 256
    local b4 = math.floor(value / 16777216) % 256

    return string.format("%02X %02X %02X %02X %02X", op, b1, b2, b3, b4)
end

local plant_struct_size = 0x14C -- true size is 0x146, 4 bytes are unused
local slot_seed_struct_size = 0x50
local zombie_struct_size = 0x15c

-- PLANTS --
do
    local function asm_place_plant(row, col, type, imitater, izombie)
        memory.asm_init()

        if imitater then
            memory.asm_push_dword(type)
            memory.asm_push_dword(48)
        else
            memory.asm_push_dword(0xFFFFFFFF) -- -1
            memory.asm_push_dword(type)
        end

        memory.asm_mov_reg_imm(EAX, row)
        memory.asm_push_dword(col)

        memory.asm_mov_dword_ptr_reg(EBP, Offsets.lawn)
        memory.asm_mov_dword_ptr_reg_add(EBP, Offsets.board)
        memory.asm_push_reg(EBP)

        memory.asm_call(Callbacks.put_plant)
        memory.asm_ret()

        return memory.asm_code_inject()
    end

    -- Returns a plant instance or nil
    function game.placePlant(x, y, type, imitater)
        -- if any is nil, invalidate it
        x = x or -1
        y = y or -1
        type = type or -1
        imitater = imitater or false -- default false

        -- val (check row, col and is plant type valid)
        if isInvalidPos(x, y) or (type < 0 or type > 56) then return nil end

        local izombie = false
        return NewPlantInstance(asm_place_plant(y, x, type, imitater, izombie))
    end

    -- Returns an array with the addresses of the plants placed
    function game.placePlants(x1, x2, y1, y2, type, imitater)
        local plants = {}
        for x = x1, x2 do
            for y = y1, y2 do
                table.insert(plants, game.placePlant(x, y, type, imitater))
            end
        end
        return plants
    end

    local function asm_clear_plant(plant) -- address
        memory.asm_init()

        memory.asm_push_dword(plant) -- arg1
        memory.asm_call(Callbacks.delete_plant)

        memory.asm_ret()
        return memory.asm_code_inject()

        --[[ this might work aswell (Plant::Die)
        memory.asm_init()
        memory.asm_mov_reg_imm(memory.ESI, plantAddr)  -- ESI = plantAddr
        memory.asm_push_reg(memory.ESI)                -- push ESI
        memory.asm_call(0x4679B0)                      -- call Die
        memory.asm_ret()
        return memory.asm_code_inject()
        ]]
    end

    function game.clearPlant(plant)
        if not plant then return false end -- false or nil?
        return asm_clear_plant(plant)
    end

    -- Removes ALL the plants at (x, y)
    function game.clearPlantAt(x, y)
        if isInvalidPos(x, y) then return false end

        for _, plant in ipairs(game.getPlants(true)) do
            if plant.x() == x and plant.y() == y then
                plant.clear()
            end
        end
    end
    -- e.g: game.placePlants(0, 8, 0, 6, Plants.squash.id) -- "6" is used instead of getColCount(), because the validation "if isInvalidPos(x, y)" skips without any issue
    -- loops (such as calling clearPlantsAt multiple times) are not recommended, use asm functions to avoid repeated blockMainLoop() calls, which often end up in a crash
    -- will be optimized and fixed

    -- Returns a plant instance of each plant in the board
    ---@return PlantInstance[]
    function game.getPlants(ignoreDead)
        ignoreDead = ignoreDead or false

        local plants = {}
        for _, plant in ipairs(game.getPlantsRaw(ignoreDead)) do
            table.insert(plants, NewPlantInstance(plant))
        end
        return plants
    end

    -- Returns addresses of each plant in the board
    ---@return integer[]
    function game.getPlantsRaw(ignoreDead)
        ignoreDead = ignoreDead or false

        local plant_offset = memory.readInt({Offsets.lawn, Offsets.board, Offsets.plant_offset})
        local plants_count = memory.readInt({Offsets.lawn, Offsets.board, Offsets.plants_count_max}) -- NOT getPlantCount()!!
        if plants_count == 0 then return {} end

        local plants = {}
        for i = 0, plants_count - 1 do
            local addr = plant_offset + i * plant_struct_size

            if ignoreDead and memory.readByte({addr + Offsets.plant_dead}) == 1 then goto continue end
            table.insert(plants, addr)

            ::continue::
        end

        return plants
    end

    function game._getPlantCount()
        return {Offsets.lawn, Offsets.board, Offsets.plants_count}
    end

    function game.getPlantCount() -- no setter because unsafe
        return memory.readInt(game._getPlantCount())
    end

    function game.clearAllPlants()
        local ui = game.getGameUI()
        if not (ui == 2 or ui == 3) then return 0 end

        local plants_cleared = 0

        for _, plant in ipairs(game.getPlants(true)) do
            if plant.dead() or plant.squished() then
                -- using raw addresses might be slightly more performant?
                plant.clear()
                plants_cleared = plants_cleared + 1
            end
        end

        return plants_cleared
    end

    function game.setSleeping(plant, sleeping)
        memory.asm_init()

        -- C++: asm_mov_exx(Reg::EDI, addr);
        memory.asm_mov_reg_imm(EAX, plant)

        memory.asm_push_byte(sleeping and 1 or 0)
        memory.asm_call(Callbacks.set_plant_sleeping)

        memory.asm_ret()
        return memory.asm_code_inject()
    end
end

-- ZOMBIES --
do
    local function asm_place_zombie(row, col, type)
        memory.asm_init()

        -- push row, push type, mov eax col
        memory.asm_push_dword(row)
        memory.asm_push_dword(type)
        memory.asm_mov_reg_imm(EAX, col)

        -- get challenge pointer?
        memory.asm_mov_dword_ptr_reg(ECX, Offsets.lawn)
        memory.asm_mov_dword_ptr_reg_add(ECX, Offsets.board)
        memory.asm_mov_dword_ptr_reg_add(ECX, Offsets.challenge)

        -- asm callback
        memory.asm_call(Callbacks.put_zombie)

        memory.asm_ret() -- add byte 0xC3

        -- returns something related to type, not zombie addr
        return memory.asm_code_inject()
    end

    local function asm_place_zombie_in_row(y, type)
        memory.asm_init()

        memory.asm_mov_dword_ptr_reg(EAX, Offsets.lawn)
        memory.asm_mov_dword_ptr_reg_add(EAX, Offsets.board)

        memory.asm_push_dword(y) -- row/col 0 forced
        memory.asm_push_dword(type) -- type

        -- asm callback
        memory.asm_call(Callbacks.put_zombie_in_row)

        memory.asm_ret() -- add byte 0xC3

        -- returns zombie pointer unlike asm_place_zombie!
        return memory.asm_code_inject()
    end

    -- The X and Y start from top left to bottom right, just like plants<br>
    -- Returns the address of the zombie placed or nil
    function game.placeZombie(x, y, type)
        -- if any is nil, invalidate it
        x = x or -1
        y = y or -1
        type = type or 0 -- default to normal

        if isInvalidPos(x, y) or (type < 0 or type > 32) then return nil end

        local zombies_before = game.getZombies(true)

        if (type == 25) then -- zomboss
            asm_place_zombie_in_row(0, 25) -- equal as game.placeZombieNaturally(0, 25)
        else
            asm_place_zombie(x, y, type)
        end
        return table.substract(game.getZombies(true), zombies_before)[1] -- get address or nil
    end

    function game.placeZombies(x1, x2, y1, y2, type)
        if type == 25 then return asm_place_zombie_in_row(0, 25) end -- place one only!

        local zombies = {}
        for x = x1, x2 do
            for y = y1, y2 do
                table.insert(zombies, game.placeZombie(x, y, type))
            end
        end
        return zombies
    end

    -- Places a zombie naturally in the given Y position, it's X float position is 800.0<br>
    -- Returns the address of the zombie placed or nil
    function game.placeZombieNaturally(y, type)
        y = y or -1 -- invalidate
        type = type or 0 -- default to normal

        if isInvalidPos(0, y) or (type < 0 or type > 32) then return nil end

        return asm_place_zombie_in_row(y, type)
    end

    function game._getZombieCount()
        return {Offsets.lawn, Offsets.board, Offsets.zombies_count}
    end

    function game.getZombieCount()
        return memory.readInt(game._getZombieCount())
    end

    function game.getZombies(ignoreDead)
        ignoreDead = ignoreDead or false

        local zombie_offset = memory.readInt({Offsets.lawn, Offsets.board, Offsets.zombie_offset})
        local zombies_count = memory.readInt({Offsets.lawn, Offsets.board, Offsets.zombies_count_max}) -- NOT getZombieCount()!!
        if zombies_count == 0 then return {} end

        local zombies = {}
        for i = 0, zombies_count - 1 do
            local addr = zombie_offset + i * zombie_struct_size

            if ignoreDead and memory.readByte({addr + Offsets.zombie_dead}) == 1 then goto continue end
            table.insert(zombies, addr)--zombies[i + 1] = addr

            ::continue::
        end

        return zombies
    end

    function game.killZombie(zombie)
        if not zombie then return false end
        memory.writeByte({zombie + Offsets.zombie_dead}, 1) -- or set status to dead?
    end
end

-- GRAVES, RAKES
do
    function game.asm_place_grave(x, y)
        memory.asm_init()

        memory.asm_mov_dword_ptr_reg(EDX, Offsets.lawn)
        memory.asm_mov_dword_ptr_reg_add(EDX, Offsets.board)
        memory.asm_mov_dword_ptr_reg_add(EDX, Offsets.challenge)

        memory.asm_push_reg(EDX)
        memory.asm_mov_reg_imm(EDI, y)
        memory.asm_mov_reg_imm(EBX, x)

        memory.asm_call(Callbacks.put_grave)

        memory.asm_ret() -- add byte 0xC3
        return memory.asm_code_inject()
    end

    function game.placeGrave(x, y)
        if isInvalidPos(x, y) then return nil end

        return game.asm_place_grave(y, x)
    end
end

-- PROJECTILES
do
    function game.asm_place_projectile(x, y, row, type)
        memory.asm_init()
        
        -- SOLO i push necessari
        memory.asm_push_dword(type)
        memory.asm_push_dword(row)
        memory.asm_push_dword(y)
        memory.asm_push_dword(x)
        
        -- base pointer (come fai in placePlant)
        memory.asm_mov_dword_ptr_reg(EAX, Offsets.lawn)
        memory.asm_mov_dword_ptr_reg_add(EAX, Offsets.board)
        
        memory.asm_call(0x0040D620)
        memory.asm_ret()
        
        return memory.asm_code_inject()  -- EAX avrà ProjectileObject
    end
end

-- SEED CARDS --
do
    function game.getSlotSeed(index)
        local slot_offset = memory.readMemory({Offsets.lawn, Offsets.board, Offsets.slot_offset})
        -- if slot_offset == nil then return nil end

        local base = slot_offset + (index * slot_seed_struct_size)

        -- working with this edit: making sure 1 element in the table in readMemory isn't dereferenced but read directly
        local seed_type = memory.readMemory({base + Offsets.slot_seed_type})
        local seed_type_im = memory.readMemory({base + Offsets.slot_seed_type_im})

        -- imitater is 48
        return seed_type == 48 and seed_type_im + 48 or seed_type
    end

    function game.setSlotSeed(index, type, imitater)
        imitater = imitater or false

        local slot_offset = memory.readMemory({Offsets.lawn, Offsets.board, Offsets.slot_offset})
        local base = slot_offset + (index * slot_seed_struct_size)

        memory.writeMemory({base + Offsets.slot_seed_type}, imitater and 48 or type)
        memory.writeMemory({base + Offsets.slot_seed_type_im}, imitater and type or -1)
    end
end

function game._sun() -- chain of pointers
    return {Offsets.lawn, Offsets.board, Offsets.sun}
end

game.sun = CreateGetterSetter(game._sun())

-- Instances:
do
    ---@return PlantInstance|nil
    function NewPlantInstance(address)
        if address == nil then return nil end
        -- The difference between plant_row, plant_offsetx and plant_xpos_visual is that:
        -- plant_row            is the actual position
        -- plant_offsetx        might be used for shaking animations and by default is 0
        -- plant_xpos_visual    is the visual position which is updated once when the plant is initialized

        ---@class PlantInstance
        local t = {
            address = address,
            type = CreateGetterSetter(address + Offsets.plant_type, "int"), -- Read and written as byte
            x = CreateGetterSetter(address + Offsets.plant_row, "short"), -- Read and written as short
            y = CreateGetterSetter(address + Offsets.plant_col, "short"), -- Read and written as short
            x_visual = CreateGetterSetter(address + Offsets.plant_xpos_visual, "int"), -- Read and written as int
            y_visual = CreateGetterSetter(address + Offsets.plant_ypos_visual, "int"), -- Read and written as int
            x_offset = CreateGetterSetter(address + Offsets.plant_offsetx, "float"), -- Read and written as float
            y_offset = CreateGetterSetter(address + Offsets.plant_offsety, "float"), -- Read and written as float
            visible = CreateGetterSetter(address + Offsets.plant_visible, "bool"), -- Read and written as bool
            ability_timer = CreateGetterSetter(address + Offsets.plant_ability_timer, "int"), -- Read and written as int
            health = CreateGetterSetter(address + Offsets.plant_health, "int"), -- Read and written as int
            max_health = CreateGetterSetter(address + Offsets.plant_max_health, "int"), -- Read and written as int
            dead = CreateGetterSetter_READONLY(address + Offsets.plant_dead, "bool"), -- Read and written as bool
            squished = CreateGetterSetter_READONLY(address + Offsets.plant_squished, "bool"), -- Read and written as bool
            asleep = CreateGetterSetter_READONLY(address + Offsets.plant_asleep, "bool"), -- Read and written as bool

            -- Clears/Kills the plant, <b>address</b> will point to a dead plant and could be reused by the game
            clear = function()
                return game.clearPlant(address)
            end,

            setSleeping = function(bool)
                return game.setSleeping(address, (bool == nil) and true or bool)
            end,
        }
        -- # DO NOT USE THIS!
        t.setPosition = function(x, y)
            if isInvalidPos(x, y) then return false end
            t.x(x)
            t.y(y)
            -- FIXME: this is not correct!
            t.x_visual(40 + x * 80)
            t.y_visual(80 + y * 80)
            return true
        end
        return t
    end
end

return game, memory