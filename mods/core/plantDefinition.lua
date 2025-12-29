require("offsets")

--[[ "PlantDefinition" at 0x69F2B0 is made up with these arguments:
SeedType                mSeedType;          //+0x0
Image**                 mPlantImage;        //+0x4
ReanimationType         mReanimationType;   //+0x8
int                     mPacketIndex;       //+0xC
int                     mSeedCost;          //+0x10
int                     mRefreshTime;       //+0x14
PlantSubClass           mSubClass;          //+0x18
int                     mLaunchRate;        //+0x1C
const SexyChar*         mPlantName;         //+0x20

-- Class' size is 0x24
-- Which means to get a plant's cost: 0x69F2B0 + ((type * 0x24) + 0x10) where 0x10 is the cost offset (look above)
]]
local base = 0x69F2B0
local class_size = 0x24

-- used for Plant.random()
local plant_ranges = {
    day = {1, 8},
    night = {9, 16},
    pool = {17, 24},
    fog = {25, 32},
    roof = {33, 40},
    upgrade = {41, 48},
    special = {49, 57} -- 9 plants, others are 8
}

-- This is not fancy but the intellisense is nice, every address is hardcoded but were checked many times to ensure they are correct
-- "Plants." shows every variable and "random", the inner functions are also shown

---@enum Plants
Plants = {
    -- day

    peashooter = {id = 0, address = 0x69F2B0, cost = CreateGetterSetter(0x69F2C0), recharge = CreateGetterSetter(0x69F2C4), _cost = 0x69F2C0, _recharge = 0x69F2C4}, -- cost = 100, recharge = 750
    sunflower = {id = 1, address = 0x69F2D4, cost = CreateGetterSetter(0x69F2E4), recharge = CreateGetterSetter(0x69F2E8), _cost = 0x69F2E4, _recharge = 0x69F2E8}, -- cost = 50, recharge = 750
    cherry_bomb = {id = 2, address = 0x69F2F8, cost = CreateGetterSetter(0x69F308), recharge = CreateGetterSetter(0x69F30C), _cost = 0x69F308, _recharge = 0x69F30C}, -- cost = 150, recharge = 5000
    wall_nut = {id = 3, address = 0x69F31C, cost = CreateGetterSetter(0x69F32C), recharge = CreateGetterSetter(0x69F330), _cost = 0x69F32C, _recharge = 0x69F330}, -- cost = 50, recharge = 3000
    potato_mine = {id = 4, address = 0x69F340, cost = CreateGetterSetter(0x69F350), recharge = CreateGetterSetter(0x69F354), _cost = 0x69F350, _recharge = 0x69F354}, -- cost = 25, recharge = 3000
    snow_pea = {id = 5, address = 0x69F364, cost = CreateGetterSetter(0x69F374), recharge = CreateGetterSetter(0x69F378), _cost = 0x69F374, _recharge = 0x69F378}, -- cost = 175, recharge = 750
    chomper = {id = 6, address = 0x69F388, cost = CreateGetterSetter(0x69F398), recharge = CreateGetterSetter(0x69F39C), _cost = 0x69F398, _recharge = 0x69F39C}, -- cost = 150, recharge = 750
    repeater = {id = 7, address = 0x69F3AC, cost = CreateGetterSetter(0x69F3BC), recharge = CreateGetterSetter(0x69F3C0), _cost = 0x69F3BC, _recharge = 0x69F3C0}, -- cost = 200, recharge = 750

    -- night

    puff_shroom = {id = 8, address = 0x69F3D0, cost = CreateGetterSetter(0x69F3E0), recharge = CreateGetterSetter(0x69F3E4), _cost = 0x69F3E0, _recharge = 0x69F3E4}, -- cost = 0, recharge = 750
    sun_shroom = {id = 9, address = 0x69F3F4, cost = CreateGetterSetter(0x69F404), recharge = CreateGetterSetter(0x69F408), _cost = 0x69F404, _recharge = 0x69F408}, -- cost = 25, recharge = 750
    fume_shroom = {id = 10, address = 0x69F418, cost = CreateGetterSetter(0x69F428), recharge = CreateGetterSetter(0x69F42C), _cost = 0x69F428, _recharge = 0x69F42C}, -- cost = 75, recharge = 750
    grave_buster = {id = 11, address = 0x69F43C, cost = CreateGetterSetter(0x69F44C), recharge = CreateGetterSetter(0x69F450), _cost = 0x69F44C, _recharge = 0x69F450}, -- cost = 75, recharge = 750
    hypno_shroom = {id = 12, address = 0x69F460, cost = CreateGetterSetter(0x69F470), recharge = CreateGetterSetter(0x69F474), _cost = 0x69F470, _recharge = 0x69F474}, -- cost = 75, recharge = 3000
    scaredy_shroom = {id = 13, address = 0x69F484, cost = CreateGetterSetter(0x69F494), recharge = CreateGetterSetter(0x69F498), _cost = 0x69F494, _recharge = 0x69F498}, -- cost = 25, recharge = 750
    ice_shroom = {id = 14, address = 0x69F4A8, cost = CreateGetterSetter(0x69F4B8), recharge = CreateGetterSetter(0x69F4BC), _cost = 0x69F4B8, _recharge = 0x69F4BC}, -- cost = 75, recharge = 5000
    doom_shroom = {id = 15, address = 0x69F4CC, cost = CreateGetterSetter(0x69F4DC), recharge = CreateGetterSetter(0x69F4E0), _cost = 0x69F4DC, _recharge = 0x69F4E0}, -- cost = 125, recharge = 5000

    -- pool

    lily_pad = {id = 16, address = 0x69F4F0, cost = CreateGetterSetter(0x69F500), recharge = CreateGetterSetter(0x69F504), _cost = 0x69F500, _recharge = 0x69F504}, -- cost = 25, recharge = 750
    squash = {id = 17, address = 0x69F514, cost = CreateGetterSetter(0x69F524), recharge = CreateGetterSetter(0x69F528), _cost = 0x69F524, _recharge = 0x69F528}, -- cost = 50, recharge = 3000
    threepeater = {id = 18, address = 0x69F538, cost = CreateGetterSetter(0x69F548), recharge = CreateGetterSetter(0x69F54C), _cost = 0x69F548, _recharge = 0x69F54C}, -- cost = 325, recharge = 750
    tangle_kelp = {id = 19, address = 0x69F55C, cost = CreateGetterSetter(0x69F56C), recharge = CreateGetterSetter(0x69F570), _cost = 0x69F56C, _recharge = 0x69F570}, -- cost = 25, recharge = 3000
    jalapeno = {id = 20, address = 0x69F580, cost = CreateGetterSetter(0x69F590), recharge = CreateGetterSetter(0x69F594), _cost = 0x69F590, _recharge = 0x69F594}, -- cost = 125, recharge = 5000
    spikeweed = {id = 21, address = 0x69F5A4, cost = CreateGetterSetter(0x69F5B4), recharge = CreateGetterSetter(0x69F5B8), _cost = 0x69F5B4, _recharge = 0x69F5B8}, -- cost = 100, recharge = 750
    torchwood = {id = 22, address = 0x69F5C8, cost = CreateGetterSetter(0x69F5D8), recharge = CreateGetterSetter(0x69F5DC), _cost = 0x69F5D8, _recharge = 0x69F5DC}, -- cost = 175, recharge = 750
    tall_nut = {id = 23, address = 0x69F5EC, cost = CreateGetterSetter(0x69F5FC), recharge = CreateGetterSetter(0x69F600), _cost = 0x69F5FC, _recharge = 0x69F600}, -- cost = 125, recharge = 3000

    -- fog

    sea_shroom = {id = 24, address = 0x69F610, cost = CreateGetterSetter(0x69F620), recharge = CreateGetterSetter(0x69F624), _cost = 0x69F620, _recharge = 0x69F624}, -- cost = 0, recharge = 3000
    plantern = {id = 25, address = 0x69F634, cost = CreateGetterSetter(0x69F644), recharge = CreateGetterSetter(0x69F648), _cost = 0x69F644, _recharge = 0x69F648}, -- cost = 25, recharge = 3000
    cactus = {id = 26, address = 0x69F658, cost = CreateGetterSetter(0x69F668), recharge = CreateGetterSetter(0x69F66C), _cost = 0x69F668, _recharge = 0x69F66C}, -- cost = 125, recharge = 750
    blover = {id = 27, address = 0x69F67C, cost = CreateGetterSetter(0x69F68C), recharge = CreateGetterSetter(0x69F690), _cost = 0x69F68C, _recharge = 0x69F690}, -- cost = 100, recharge = 750
    split_pea = {id = 28, address = 0x69F6A0, cost = CreateGetterSetter(0x69F6B0), recharge = CreateGetterSetter(0x69F6B4), _cost = 0x69F6B0, _recharge = 0x69F6B4}, -- cost = 125, recharge = 750
    starfruit = {id = 29, address = 0x69F6C4, cost = CreateGetterSetter(0x69F6D4), recharge = CreateGetterSetter(0x69F6D8), _cost = 0x69F6D4, _recharge = 0x69F6D8}, -- cost = 125, recharge = 750
    pumpkin = {id = 30, address = 0x69F6E8, cost = CreateGetterSetter(0x69F6F8), recharge = CreateGetterSetter(0x69F6FC), _cost = 0x69F6F8, _recharge = 0x69F6FC}, -- cost = 125, recharge = 3000
    magnet_shroom = {id = 31, address = 0x69F70C, cost = CreateGetterSetter(0x69F71C), recharge = CreateGetterSetter(0x69F720), _cost = 0x69F71C, _recharge = 0x69F720}, -- cost = 100, recharge = 750

    -- roof

    cabbage_pult = {id = 32, address = 0x69F730, cost = CreateGetterSetter(0x69F740), recharge = CreateGetterSetter(0x69F744), _cost = 0x69F740, _recharge = 0x69F744}, -- cost = 100, recharge = 750
    flower_pot = {id = 33, address = 0x69F754, cost = CreateGetterSetter(0x69F764), recharge = CreateGetterSetter(0x69F768), _cost = 0x69F764, _recharge = 0x69F768}, -- cost = 25, recharge = 750
    kernel_pult = {id = 34, address = 0x69F778, cost = CreateGetterSetter(0x69F788), recharge = CreateGetterSetter(0x69F78C), _cost = 0x69F788, _recharge = 0x69F78C}, -- cost = 100, recharge = 750
    coffee_bean = {id = 35, address = 0x69F79C, cost = CreateGetterSetter(0x69F7AC), recharge = CreateGetterSetter(0x69F7B0), _cost = 0x69F7AC, _recharge = 0x69F7B0}, -- cost = 75, recharge = 750
    garlic = {id = 36, address = 0x69F7C0, cost = CreateGetterSetter(0x69F7D0), recharge = CreateGetterSetter(0x69F7D4), _cost = 0x69F7D0, _recharge = 0x69F7D4}, -- cost = 50, recharge = 750
    umbrella_leaf = {id = 37, address = 0x69F7E4, cost = CreateGetterSetter(0x69F7F4), recharge = CreateGetterSetter(0x69F7F8), _cost = 0x69F7F4, _recharge = 0x69F7F8}, -- cost = 100, recharge = 750
    marigold = {id = 38, address = 0x69F808, cost = CreateGetterSetter(0x69F818), recharge = CreateGetterSetter(0x69F81C), _cost = 0x69F818, _recharge = 0x69F81C}, -- cost = 50, recharge = 3000
    melon_pult = {id = 39, address = 0x69F82C, cost = CreateGetterSetter(0x69F83C), recharge = CreateGetterSetter(0x69F840), _cost = 0x69F83C, _recharge = 0x69F840}, -- cost = 300, recharge = 750

    -- upgrades

    gatling_pea = {id = 40, address = 0x69F850, cost = CreateGetterSetter(0x69F860), recharge = CreateGetterSetter(0x69F864), _cost = 0x69F860, _recharge = 0x69F864}, -- cost = 250, recharge = 5000
    twin_sunflower = {id = 41, address = 0x69F874, cost = CreateGetterSetter(0x69F884), recharge = CreateGetterSetter(0x69F888), _cost = 0x69F884, _recharge = 0x69F888}, -- cost = 150, recharge = 5000
    gloom_shroom = {id = 42, address = 0x69F898, cost = CreateGetterSetter(0x69F8A8), recharge = CreateGetterSetter(0x69F8AC), _cost = 0x69F8A8, _recharge = 0x69F8AC}, -- cost = 150, recharge = 5000
    cattail = {id = 43, address = 0x69F8BC, cost = CreateGetterSetter(0x69F8CC), recharge = CreateGetterSetter(0x69F8D0), _cost = 0x69F8CC, _recharge = 0x69F8D0}, -- cost = 225, recharge = 5000
    winter_melon = {id = 44, address = 0x69F8E0, cost = CreateGetterSetter(0x69F8F0), recharge = CreateGetterSetter(0x69F8F4), _cost = 0x69F8F0, _recharge = 0x69F8F4}, -- cost = 200, recharge = 5000
    gold_magnet = {id = 45, address = 0x69F904, cost = CreateGetterSetter(0x69F914), recharge = CreateGetterSetter(0x69F918), _cost = 0x69F914, _recharge = 0x69F918}, -- cost = 50, recharge = 5000
    spikerock = {id = 46, address = 0x69F928, cost = CreateGetterSetter(0x69F938), recharge = CreateGetterSetter(0x69F93C), _cost = 0x69F938, _recharge = 0x69F93C}, -- cost = 125, recharge = 5000
    cob_cannon = {id = 47, address = 0x69F94C, cost = CreateGetterSetter(0x69F95C), recharge = CreateGetterSetter(0x69F960), _cost = 0x69F95C, _recharge = 0x69F960}, -- cost = 500, recharge = 5000

    -- special (might cause crashes)

    imitater = {id = 48}, -- variable cost and recharge?
    explode_o_nut = {id = 49},
    giant_wallnut = {id = 50},
    sprout = {id = 51},
    reverse_repeater = {id = 52},
    giant_sunflower = {id = 53},
    giant_wallnut2 = {id = 54},
    giant_marigold = {id = 55},
    tree_of_wisdom = {id = 56},

    -- TODO: test it
    ---@param type nil|"day"|"night"|"pool"|"fog"|"roof"|"upgrade"|"special"
    random = function(type)
        return nil --FIXME:
        -- local _plants = table.toArray(Plants)
        -- if not type then return _plants[math.random(1, 57)] end

        -- local r = plant_ranges[type]
        -- return _plants[math.random(r[1], r[2])]
    end
}