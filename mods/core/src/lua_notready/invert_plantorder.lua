local game, memory = require("core")
memory.start()

--[[
Decomp:
// 0x69F2B0
PlantDefinition gPlantDefs[SeedType::NUM_SEED_TYPES] = {
    { SeedType::SEED_PEASHOOTER,        nullptr, ReanimationType::REANIM_PEASHOOTER,    0,  100,    750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("PEASHOOTER") },
    { SeedType::SEED_SUNFLOWER,         nullptr, ReanimationType::REANIM_SUNFLOWER,     1,  50,     750,    PlantSubClass::SUBCLASS_NORMAL,     2500,   _S("SUNFLOWER") },
    { SeedType::SEED_CHERRYBOMB,        nullptr, ReanimationType::REANIM_CHERRYBOMB,    3,  150,    5000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("CHERRY_BOMB") },
    { SeedType::SEED_WALLNUT,           nullptr, ReanimationType::REANIM_WALLNUT,       2,  50,     3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("WALL_NUT") },
    { SeedType::SEED_POTATOMINE,        nullptr, ReanimationType::REANIM_POTATOMINE,    37, 25,     3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("POTATO_MINE") },
    { SeedType::SEED_SNOWPEA,           nullptr, ReanimationType::REANIM_SNOWPEA,       4,  175,    750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("SNOW_PEA") },
    { SeedType::SEED_CHOMPER,           nullptr, ReanimationType::REANIM_CHOMPER,       31, 150,    750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("CHOMPER") },
    { SeedType::SEED_REPEATER,          nullptr, ReanimationType::REANIM_REPEATER,      5,  200,    750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("REPEATER") },
    { SeedType::SEED_PUFFSHROOM,        nullptr, ReanimationType::REANIM_PUFFSHROOM,    6,  0,      750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("PUFF_SHROOM") },
    { SeedType::SEED_SUNSHROOM,         nullptr, ReanimationType::REANIM_SUNSHROOM,     7,  25,     750,    PlantSubClass::SUBCLASS_NORMAL,     2500,   _S("SUN_SHROOM") },
    { SeedType::SEED_FUMESHROOM,        nullptr, ReanimationType::REANIM_FUMESHROOM,    9,  75,     750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("FUME_SHROOM") },
    { SeedType::SEED_GRAVEBUSTER,       nullptr, ReanimationType::REANIM_GRAVE_BUSTER,  40, 75,     750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("GRAVE_BUSTER") },
    { SeedType::SEED_HYPNOSHROOM,       nullptr, ReanimationType::REANIM_HYPNOSHROOM,   10, 75,     3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("HYPNO_SHROOM") },
    { SeedType::SEED_SCAREDYSHROOM,     nullptr, ReanimationType::REANIM_SCRAREYSHROOM, 33, 25,     750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("SCAREDY_SHROOM") },
    { SeedType::SEED_ICESHROOM,         nullptr, ReanimationType::REANIM_ICESHROOM,     36, 75,     5000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("ICE_SHROOM") },
    { SeedType::SEED_DOOMSHROOM,        nullptr, ReanimationType::REANIM_DOOMSHROOM,    20, 125,    5000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("DOOM_SHROOM") },
    { SeedType::SEED_LILYPAD,           nullptr, ReanimationType::REANIM_LILYPAD,       19, 25,     750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("LILY_PAD") },
    { SeedType::SEED_SQUASH,            nullptr, ReanimationType::REANIM_SQUASH,        21, 50,     3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("SQUASH") },
    { SeedType::SEED_THREEPEATER,       nullptr, ReanimationType::REANIM_THREEPEATER,   12, 325,    750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("THREEPEATER") },
    { SeedType::SEED_TANGLEKELP,        nullptr, ReanimationType::REANIM_TANGLEKELP,    17, 25,     3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("TANGLE_KELP") },
    { SeedType::SEED_JALAPENO,          nullptr, ReanimationType::REANIM_JALAPENO,      11, 125,    5000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("JALAPENO") },
    { SeedType::SEED_SPIKEWEED,         nullptr, ReanimationType::REANIM_SPIKEWEED,     22, 100,    750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("SPIKEWEED") },
    { SeedType::SEED_TORCHWOOD,         nullptr, ReanimationType::REANIM_TORCHWOOD,     29, 175,    750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("TORCHWOOD") },
    { SeedType::SEED_TALLNUT,           nullptr, ReanimationType::REANIM_TALLNUT,       28, 125,    3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("TALL_NUT") },
    { SeedType::SEED_SEASHROOM,         nullptr, ReanimationType::REANIM_SEASHROOM,     39, 0,      3000,   PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("SEA_SHROOM") },
    { SeedType::SEED_PLANTERN,          nullptr, ReanimationType::REANIM_PLANTERN,      38, 25,     3000,   PlantSubClass::SUBCLASS_NORMAL,     2500,   _S("PLANTERN") },
    { SeedType::SEED_CACTUS,            nullptr, ReanimationType::REANIM_CACTUS,        15, 125,    750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("CACTUS") },
    { SeedType::SEED_BLOVER,            nullptr, ReanimationType::REANIM_BLOVER,        18, 100,    750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("BLOVER") },
    { SeedType::SEED_SPLITPEA,          nullptr, ReanimationType::REANIM_SPLITPEA,      32, 125,    750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("SPLIT_PEA") },
    { SeedType::SEED_STARFRUIT,         nullptr, ReanimationType::REANIM_STARFRUIT,     30, 125,    750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("STARFRUIT") },
    { SeedType::SEED_PUMPKINSHELL,      nullptr, ReanimationType::REANIM_PUMPKIN,       25, 125,    3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("PUMPKIN") },
    { SeedType::SEED_MAGNETSHROOM,      nullptr, ReanimationType::REANIM_MAGNETSHROOM,  35, 100,    750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("MAGNET_SHROOM") },
    { SeedType::SEED_CABBAGEPULT,       nullptr, ReanimationType::REANIM_CABBAGEPULT,   13, 100,    750,    PlantSubClass::SUBCLASS_SHOOTER,    300,    _S("CABBAGE_PULT") },
    { SeedType::SEED_FLOWERPOT,         nullptr, ReanimationType::REANIM_FLOWER_POT,    33, 25,     750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("FLOWER_POT") },
    { SeedType::SEED_KERNELPULT,        nullptr, ReanimationType::REANIM_KERNELPULT,    13, 100,    750,    PlantSubClass::SUBCLASS_SHOOTER,    300,    _S("KERNEL_PULT") },
    { SeedType::SEED_INSTANT_COFFEE,    nullptr, ReanimationType::REANIM_COFFEEBEAN,    33, 75,     750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("COFFEE_BEAN") },
    { SeedType::SEED_GARLIC,            nullptr, ReanimationType::REANIM_GARLIC,        8,  50,     750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("GARLIC") },
    { SeedType::SEED_UMBRELLA,          nullptr, ReanimationType::REANIM_UMBRELLALEAF,  23, 100,    750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("UMBRELLA_LEAF") },
    { SeedType::SEED_MARIGOLD,          nullptr, ReanimationType::REANIM_MARIGOLD,      24, 50,     3000,   PlantSubClass::SUBCLASS_NORMAL,     2500,   _S("MARIGOLD") },
    { SeedType::SEED_MELONPULT,         nullptr, ReanimationType::REANIM_MELONPULT,     14, 300,    750,    PlantSubClass::SUBCLASS_SHOOTER,    300,    _S("MELON_PULT") },
    
    // other specials
    { SeedType::SEED_GATLINGPEA,        nullptr, ReanimationType::REANIM_GATLINGPEA,    5,  250,    5000,   PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("GATLING_PEA") },
    { SeedType::SEED_TWINSUNFLOWER,     nullptr, ReanimationType::REANIM_TWIN_SUNFLOWER,1,  150,    5000,   PlantSubClass::SUBCLASS_NORMAL,     2500,   _S("TWIN_SUNFLOWER") },
    { SeedType::SEED_GLOOMSHROOM,       nullptr, ReanimationType::REANIM_GLOOMSHROOM,   27, 150,    5000,   PlantSubClass::SUBCLASS_SHOOTER,    200,    _S("GLOOM_SHROOM") },
    { SeedType::SEED_CATTAIL,           nullptr, ReanimationType::REANIM_CATTAIL,       27, 225,    5000,   PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("CATTAIL") },
    { SeedType::SEED_WINTERMELON,       nullptr, ReanimationType::REANIM_WINTER_MELON,  27, 200,    5000,   PlantSubClass::SUBCLASS_SHOOTER,    300,    _S("WINTER_MELON") },
    { SeedType::SEED_GOLD_MAGNET,       nullptr, ReanimationType::REANIM_GOLD_MAGNET,   27, 50,     5000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("GOLD_MAGNET") },
    { SeedType::SEED_SPIKEROCK,         nullptr, ReanimationType::REANIM_SPIKEROCK,     27, 125,    5000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("SPIKEROCK") },
    { SeedType::SEED_COBCANNON,         nullptr, ReanimationType::REANIM_COBCANNON,     16, 500,    5000,   PlantSubClass::SUBCLASS_NORMAL,     600,    _S("COB_CANNON") },
    { SeedType::SEED_IMITATER,          nullptr, ReanimationType::REANIM_IMITATER,      33, 0,      750,    PlantSubClass::SUBCLASS_NORMAL,     0,      _S("IMITATER") },
    { SeedType::SEED_EXPLODE_O_NUT,     nullptr, ReanimationType::REANIM_WALLNUT,       2,  0,      3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("EXPLODE_O_NUT") },
    { SeedType::SEED_GIANT_WALLNUT,     nullptr, ReanimationType::REANIM_WALLNUT,       2,  0,      3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("GIANT_WALLNUT") },
    { SeedType::SEED_SPROUT,            nullptr, ReanimationType::REANIM_ZENGARDEN_SPROUT,          33, 0,      3000,   PlantSubClass::SUBCLASS_NORMAL,     0,      _S("SPROUT") },
    { SeedType::SEED_LEFTPEATER,        nullptr, ReanimationType::REANIM_REPEATER,      5,  200,    750,    PlantSubClass::SUBCLASS_SHOOTER,    150,    _S("REPEATER") }
};

-- Struct size is 0x24, because:

class PlantDefinition
{
public:
    SeedType                mSeedType;          //+0x0
    Image**                 mPlantImage;        //+0x4
    ReanimationType         mReanimationType;   //+0x8
    int                     mPacketIndex;       //+0xC
    int                     mSeedCost;          //+0x10
    int                     mRefreshTime;       //+0x14
    PlantSubClass           mSubClass;          //+0x18
    int                     mLaunchRate;        //+0x1C
    const SexyChar*         mPlantName;         //+0x20
};
extern PlantDefinition gPlantDefs[SeedType::NUM_SEED_TYPES];
]]

-- CHANGE PLANT ORDER --

-- change starting sun cost when level 1-1:
--[[
// 0x40AF90
void Board::InitLevel()
...
else if (mApp->IsFirstTimeAdventureMode() && mLevel == 1)
{
    mSunMoney = 150;
}
]]
memory.writeInt(0x0040B08F, 0x1C2) -- 0x1C2 = 450, previously 150 (0x96)

memory.stop()