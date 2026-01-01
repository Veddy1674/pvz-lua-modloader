local defs = {}

local function gettersetter(addr, v)
    local memory = require("memory")
    if v ~= nil then
        if type == "bool" then memory.writeByte(addr, (not v and 0) or 1)
        elseif type == "byte" then memory.writeByte(addr, v)
        elseif type == "short" then memory.writeShort(addr, v)
        elseif type == "float" then memory.writeFloat(addr, v)
        else memory.writeInt(addr, v) end -- int
        return v
    else
        if type == "bool" then return memory.readByte(addr) ~= 0
        elseif type == "byte" then return memory.readByte(addr)
        elseif type == "short" then return memory.readShort(addr)
        elseif type == "float" then return memory.readFloat(addr)
        else return memory.readInt(addr) end -- int
    end
end

---@param addr integer|integer[]
---@param type? "bool"|"byte"|"short"|"int"|"float"
function CreateGetterSetter(addr, type)
    type = type or "int"
    -- If <b>v</b> is provided: writes <b>v</b> to <b>address</b> and returns <b>v</b> (setter)<br>
    -- If <b>v</b> is nil: reads from <b>address</b> and returns its value (getter)
    ---@param v? integer
    ---@return number|boolean|nil
    return function(v)
        return gettersetter(addr, v)
    end
end

---@param addr integer|integer[]
---@param type "bool"|"byte"|"short"|"int"|"float"
function CreateGetterSetter_READONLY(addr, type)
    type = type or "int"
    -- <h4>NOTE: This attribute was marked as "readonly", therefore writing to it has no effect, might crash the game or will get internally overwritten</h4>
    -- If <b>v</b> is provided: writes <b>v</b> to <b>address</b> and returns <b>v</b> (setter)<br>
    -- If <b>v</b> is nil: reads from <b>address</b> and returns its value (getter)
    ---@param v? nil -- You will get a warning if you try to write to this address, however it will still write
    ---@return number|boolean|nil
    return function(v)
        return gettersetter(addr, v)
    end
end

-- A list of memory offsets used in the game
-- int, byte, float, short, pointer and such are the data type (e.g: memory.writeInt, memory.readByte...)
-- "readonly" means the value is modified by the game, or doesn't change anything if written to
-- Question marks means I'm not sure about the data type, if it's crash-free, or what it specifically does, so use it at your own risk
---@enum Offsets
Offsets = {
    path = 0x6a6cc8,

    lawn = 0x6a9ec0,
        -- default: 10, 5 means x2 faster, 1 means x10 faster
        frame_duration = 0x454, -- byte or int?
        board = 0x768,
            -- pause screen
            game_paused = 0x164, -- byte
            -- values different than 0 and 1 seem to end up in unexpected behavior regarding the pause screen floating window...
            game_force_paused = 0x48, -- byte
            -- increments every frame when not paused
            game_clock = 0x5568, -- int
            -- Shows texts about game info, such as "ZombieCountDown" (time before next zombie(s) spawns)
            -- "CurrentWave" (increments everytime ZombieCountDown reaches 0), "ZombieHealth"...
            debug_mode = 0x55f8, -- byte
            scene = 0x554c, -- byte
            adventure_level = 0x5550, -- byte
            sun = 0x5560, -- int
            zombie_offset = 0x90,
                zombie_xpos_visual = 0x8, -- readonly?, int
                zombie_ypos_visual = 0xc, -- readonly?, int
                zombie_xpos = 0x2C, -- float
                zombie_ypos = 0x30, -- float
                zombie_layer = 0x20, -- ?
                zombie_type = 0x24, -- readonly, int
                zombie_speed = 0x34, -- float?
                zombie_frozen = 0xb4, -- byte
                zombie_buttered = 0xb0, -- byte
                zombie_iseating = 0x51, -- byte
                zombie_slow = 0xac,
                zombie_is_hypno = 0xb8, -- byte
                -- balloon zombie
                zombie_blown_away = 0xb9, -- byte
                -- whenever its value is 16777216 (256x256x256), zombie plays garlic animation and switches lane<br>
                -- whenever its value is set to 0 forcefully while eating a garlic, the animation freezes and the<br>
                -- zombie eats the garlic until it's removed, then walks normally
                zombie_garlic_effect = 0xbc, -- int
                zombie_size = 0x11c, -- ?
                zombie_state = 0x28, -- byte
                zombie_dead = 0xec, -- readonly, byte
            zombies_count = 0xa0,
            zombies_count_max = 0x94,
            plant_offset = 0xac,
                plant_xpos_visual = 0x8, -- int
                plant_ypos_visual = 0xc, -- int
                plant_row = 0x1c, -- short (byte and int also work)
                plant_col = 0x28, -- short (byte and int also work)
                plant_visible = 0x18, -- byte, 1 = visible, 0 = invisible, dead plants are theorically visible
                plant_type = 0x24, -- setting to 1 gives the plant a glow effect and produces sunflowers quickly?
                -- used for cherry bombs and similar, it decreases and explodes when it reaches 1 (0 and below makes it never explode)
                plant_ability_timer = 0x50, -- int
                -- in the decomp it's defined as "shakeOffsetX", not sure why
                plant_offsetx = 0xC0, -- float
                -- in the decomp it's' defined as "shakeOffsetY", not sure why
                plant_offsety = 0xC4, -- float
                plant_health = 0x40, -- int
                plant_max_health = 0x44, -- int
                plant_dead = 0x141, -- byte
                plant_squished = 0x142, -- byte
                plant_asleep = 0x143, -- readonly, byte
            plants_count = 0xbc,
            plants_count_max = 0xb0,
            slot_offset = 0x144,
                slot_count = 0x24,
                slot_seed_cd_past = 0x4c,
                slot_seed_cd_total = 0x50,
                slot_seed_type = 0x5c,
                slot_seed_type_im = 0x60,
            lawn_mower_offset = 0x100,
                lawn_mower_dead = 0x30, -- byte
            lawn_mower_count = 0x110,
            lawn_mower_count_max = 0x104,

    -- TODO: others...
    challenge = 0x160,

    game_mode = 0x7f8,
    game_ui = 0x7fc,
    free_planting = 0x814,

    user_data = 0x82c,
        level = 0x24,
        money = 0x28,
        playthrough = 0x2c,
        mini_games = 0x30,
        tree_height = 0xf4,
        music = 0x83c,
}

---@enum Callbacks
Callbacks = {
    sync_profile = 0x44a320,
    fade_out_level = 0x40c3e0,
    wisdom_tree = 0x42d1f0,

    put_plant = 0x40d120,
    put_plant_imitater = 0x466b80,
    put_plant_iz_style = 0x42a530,
    put_zombie = 0x42a0f0, -- lawn, board, challenge - from izombie methods! but its probably the best way to forcibly spawn
    put_zombie_in_row = 0x40ddc0, -- lawn, board, challenge
    kill_zombie = 0x530510, -- this
    put_grave = 0x426620, -- lawn, board, challenge?
    put_ladder = 0x408f40,
    put_rake = 0x40b9c0,
    put_rake_row = 0x40bb25,
    put_rake_col = 0x40ba8e,

    start_lawn_mower = 0x458da0,
    delete_lawn_mower = 0x458d10,
    restore_lawn_mower = 0x40bc70,

    delete_plant = 0x4679b0,
    delete_grid_item = 0x44d000,

    set_plant_sleeping = 0x45e860,

    puzzle_next_stage_clear = 0x429e50,
    pick_background = 0x40a160,
    delete_particle_system = 0x5160c0,

    pick_zombie_waves = 0x4092e0,
    remove_cutscene_zombies = 0x40df70,
    place_street_zombies = 0x43a140,

    play_music = 0x45b750,

    -- special
    block_main_loop = {0x552014, {0xfe}, {0xdb}},
    unlock_sun_limit = {0x430a23, {0xeb}, {0x7e}},

    -- useful for patching
    can_plant_at = 0x40E020,
    plant_is_upgradable = 0x463470,
    mouse_down_with_plant = 0x40FD30 -- when you click with a plant as your cursor
}

-- defs.health

---@enum Zombies
Zombies = {
    -- base
    zombie = 0,
    flag_zombie = 1,
    conehead_zombie = 2,
    pole_vaulting_zombie = 3,
    buckethead_zombie = 4,
    newspaper_zombie = 5,
    screen_door_zombie = 6,
    football_zombie = 7,
    dancing_zombie = 8,
    backup_dancer = 9,
    ducky_tube_zombie = 10,
    snorkel_zombie = 11,
    zomboni = 12,
    zombie_bobsled_team = 13,
    dolphin_rider_zombie = 14,
    jack_in_the_box_zombie = 15,
    balloon_zombie = 16,
    digger_zombie = 17,
    pogo_zombie = 18,
    yeti_zombie = 19,
    bungee_zombie = 20,
    ladder_zombie = 21,
    catapult_zombie = 22,
    gargantuar = 23,
    imp = 24,
    dr_zomboss = 25,

    -- special (zombotany and gigagargantuar)
    peashooter_zombie = 26,
    wall_nut_zombie = 27,
    jalapeno_zombie = 28,
    gatling_pea_zombie = 29,
    squash_zombie = 30,
    tall_nut_zombie = 31,
    gigagargantuar = 32,

    ---@param type nil|"special"
    random = function(type)
        return type == "special" and math.random(0, 32) or math.random(0, 25)
    end
}

---@enum Scenes
Scene = {
    day = 0,
    night = 1,
    pool_day = 2,
    pool_night = 3, -- fog
    roof_day = 4,
    roof_night = 5 -- final boss
}

---@class GameModes
Gamemode = {
    adventure = 0,
    survival = 1,
    survival_hard = 2,
    survival_endless = 3,
    mini_games = 4,
    puzzle = 5,
    puzzle_hard = 6,
    puzzle_endless = 7,
    versus = 8,
    coop = 9,
    survival_day = 11,
    survival_night = 12,
    survival_pool = 13,
    survival_fog = 14,
    survival_roof = 15,
    survival_day_hard = 21,
    survival_night_hard = 22,
    survival_pool_hard = 23,
    survival_fog_hard = 24,
    survival_roof_hard = 25,
    vs_mode = 31,
    i_zombie = 61,
    i_zombie_hard = 62,
    i_zombie_endless = 63,
    vase_breaker = 71,
    vase_breaker_hard = 72,
    vase_breaker_endless = 73,
    i_zombie_2 = 81,
    i_zombie_2_hard = 82,
    i_zombie_2_endless = 83,
    zen_garden = 50,

    -- Returns wheter <b>mode</b> is part of the "I, Zombie" category
    ---@param mode GameModes|integer
    is_izombie = function(mode)
        return (mode >= 61 and mode <= 63) or (mode >= 81 and mode <= 83)
    end,

    -- Returns wheter <b>mode</b> is part of the "Vase Breaker" category
    ---@param mode GameModes|integer
    is_vasebreaker = function(mode)
        return mode >= 71 and mode <= 73
    end,
}

defs.other = {
    what_sun_produces = 0x53BE0,
    what_sunflower_produces = 0x5FACB,
    what_sunshroom_produces = 0x5FABE,
    what_twinsunflower_produces_1 = 0x5FADF, what_twinsunflower_produces_2 = 0x5FAF0,
    what_marigold_produces_first = 0x5FAFC, -- silver coin
    -- when changing 0x5FAFC, 0x5FAFF must also be changed accordingly:
    -- 0x5FAFC - 219 - 220 - 221 - 222 - 223 - 224 - 226 - 233 - 234 - 235 - 236 (defs.item_type)
    -- 0x5FAFF - 99  - 98  - 97  - 96  - 95 -  94  - 92  - 85  - 84  - 83  - 82
    what_marigold_produces_second = 0x5FB0B, -- gold coin
    marigold_dropseconditem_chance = 0x5FB07, -- 1 to 100, the chance of dropping the second item instead of the first
    marigold_item_animation = 0x5FB10,
    -- 0 = sun dropping from top,
    -- 1 = seed card dropping like in "It's Raining Seeds",
    -- 2 = sun producing like from sunflower,
    -- 3 = item dropping like when zombies die and drop coins,
    -- 4 = auto collect instant,
    -- 5 = auto collect but delayed about 1 second,
    -- 6 = prize/moneybag path after Zombot has been destroyed (from right center),
    -- 7 or higher = stay on top of the screen, frozen
}

defs.item_type = {
    silver_coin = 219,
    gold_coin = 220,
    diamond = 221,
    sun = 222,
    small_sun = 223,
    big_sun = 224,
    trophy = 226,
    zombie_letter = 233,
    card = 234,
    present = 235,
    money_bag = 236,
}

-- this is extremely confusing so I recommend looking up the original google doc (not mine): 
defs.currency_type = {
    silver_coin = 1,
    gold_coin = 2,
    diamond = 3,
    sun = 4,
    small_sun = 5,
    big_sun = 6,
    trophy = 8,
    shovel = 9,
    almanac_book = 10,
    car_keys = 11,
    vase = 12,
    watering_can = 13,
    taco = 14,
    zombie_letter = 15,
    card = 16,
    present_1 = 17, present_2 = 19, present_3 = 25, present_4 = 26, present_5 = 27, -- no idea what these corrispond to
    money_bag_1 = 18, money_bag_2 = 20, -- no idea
    silver_sunflower_trophy = 21, -- the one in the main menu when the game is partially completed
    golden_sunshroom_trophy = 22, -- the one in the main menu when the game is 100% completed
    chocolate_bar_1 = 23, chocolate_bar_2 = 24, -- no idea
}

defs.setAutoCollector = function(memory, active)
    active = (active == nil) and true or active
    memory.writeByte(0x0043158F, active and -21 or 117) -- signed int8
end

return defs