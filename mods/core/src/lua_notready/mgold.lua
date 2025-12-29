local game, memory = require("core")
memory.start()

memory.writeInt(0x69F824, 80) -- production rate from 2500 to 80
memory.writeByte(0x45FAFC, 222) -- change marigold's coin type to sunflower (219 to 222)
memory.writeByte(0x45FB07, 0) -- rate to drop gold coin

local plants_list = {}
local marigolds = {} -- { {addr, } }

memory.addListener(game._getPlantCount(), function(old, new)
    if old == nil then -- first call
        plants_list = game.getPlants(true)
        return
    end

    local plants = game.getPlants(true)
    local added = table.substract(plants, plants_list)

    if #added > 0 then
        local plant = added[1]
        if memory.readInt(plant + Offsets.plant_type) == Plants.marigold.id then
            table.insert(marigolds, {plant, 80}) -- timer 1.28s
        end
        return
    end

    -- not necessary
    local removed = table.substract(plants_list, plants)
    if #removed > 0 then
        local plant = removed[1]
        if memory.readInt(plant + Offsets.plant_type) == Plants.marigold.id then
            -- remove from marigolds list
            for i, data in ipairs(marigolds) do
                if data[1] == plant then
                    table.remove(marigolds, i)
                    break
                end
            end
        end
    end
end)
memory.onUpdate(function()
    memory.processListeners()

    -- backwards iteration to allow removal
    for i = #marigolds, 1, -1 do
        local data = marigolds[i] -- {addr, timer}

        if data[2] <= 0 then
            game.clearPlant(data[1])
            table.remove(marigolds, i)
        else
            data[2] = data[2] - 1
        end
    end
end, 16)

memory.stop()