local LIFESPAN_MIN_HOURS = 1
local LIFESPAN_MAX_HOURS = 3

--- A leech instance.
---
---@class Leech
---@field index LeechIndex
---@field expireTime LeechExpireTime
local Leech = {}
Leech.__index = Leech

--- Create a new leech instance.
---
---@param index LeechIndex
---@param timestamp number
---@return Leech
function Leech:new(index, timestamp)
    local lifespan = math.random(LIFESPAN_MIN_HOURS, LIFESPAN_MAX_HOURS)
    local data = {
        index = index,
        expireTime = timestamp + lifespan,
    }
    return setmetatable(data, Leech)
end

---@return string
function Leech:getName()
    return ("Leech - %d"):format(self.index)
end

---@param ref tes3reference
---@return niNode|nil
function Leech:getSceneNode(ref)
    return ref.sceneNode:getObjectByName(self:getName()) ---@diagnostic disable-line
end

return Leech
