---@param value number
---@param min number
---@param max number
---@return number
-- Returns the value clamped between <b>min</b> and <b>max</b>
function math.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

---@param t table
---@param value any
---@param key string|function|nil
---@return boolean
-- Returns true if integer <b>value</b> is inside of the integer array
-- Alternatively if <b>key</b> is a function, the logic is customizable
function table.contains(t, value, key)
    for i = 0, #t do
        local v = t[i]
        if v then
            local actualValue
            if type(key) == "function" then
                actualValue = key(v)
            elseif key then
                actualValue = v[key]
                if type(actualValue) == "function" then
                    actualValue = actualValue()
                end
            else
                actualValue = v
            end

            if actualValue == value then return true end
        end
    end
    return false
end

function Contains(table, value) -- simplified version of table.contains
    if table == nil or type(table) ~= "table" then return false end
    for i = 1, #table do
        if table[i] == value then
            return true
        end
    end
    return false
end

---@param a table
---@param b table
---@return table
-- Returns an array of elements that are in <b>a</b> but not in <b>b</b>
--[[
```lua
local a = {0x10, 0x20}
local b = {0x10, 0x20, 0x30}
local result = table.substract(b, a)
-- result: {0x30}
```
]]
function table.substract(a, b)
    local result = {}
    local ref_hash = {}

    for _, v in ipairs(b) do
        ref_hash[v] = true
    end

    for _, v in ipairs(a) do
        if not ref_hash[v] then
            table.insert(result, v)
        end
    end

    return result
end

---@param tbl table
---@return table
-- Returns a shallow copy of <b>tbl</b>
function table.copy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end