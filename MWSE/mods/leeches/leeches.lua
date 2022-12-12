local utils = require("leeches.utils")

local LIFESPAN_MIN_HOURS = 1
local LIFESPAN_MAX_HOURS = 3

---@alias LeechIndex number
---@alias LeechExpireTime number

---@class Leech
---@field index LeechIndex
---@field expireTime LeechExpireTime

---@class Leeches
---@field activeLeeches Leech[]
---@field vacantLeeches LeechIndex[]
local Leeches = {}
Leeches.__index = Leeches

---@return Leeches
function Leeches.new()
    return setmetatable({
        activeLeeches = {},
        vacantLeeches = utils.shuffle(utils.range(#utils.getAttachPoints())),
    }, Leeches)
end

---@return Leeches
function Leeches.getOrCreate(ref)
    local t = assert(ref.data)
    t.leeches = t.leeches or Leeches.new()
    return t.leeches
end

---@param ref tes3reference
function Leeches:addLeech(ref, timestamp)
    if not ref.sceneNode then
        return
    end

    local index = table.remove(self.vacantLeeches)
    if index == nil then -- all indices are active
        return
    end

    -- TimeStamp so we can remove the leech when appropriate.
    table.insert(self.activeLeeches, {
        index = index,
        expireTime = timestamp + math.random(LIFESPAN_MIN_HOURS, LIFESPAN_MAX_HOURS),
    })

    local attachPoints = utils.getAttachPoints()
    local attachNode = assert(attachPoints[index])

    local shape = utils.getLeechMesh()
    shape.translation = attachNode.translation
    shape.rotation = attachNode.rotation
    shape.scale = attachNode.scale
    shape.name = ("Leech - %d"):format(index)

    local bone = ref.sceneNode:getObjectByName(attachNode.parent.name)
    bone:attachChild(shape)

    bone:update()
    bone:updateEffects()
    bone:updateProperties()

    tes3.messageBox("Leech Acquired! (%s)", ref)
end

---@param ref tes3reference
---@param timestamp TimeStamp
function Leeches:removeExpired(ref, timestamp)
    while true do
        local leech = self.activeLeeches[1]
        if leech == nil then
            return
        end
        if timestamp < leech.expireTime then
            return
        end
        self:removeLeech(ref)
        tes3.messageBox("Leech Expired! (%s)", ref)
    end
end

---@param ref tes3reference
function Leeches:removeLeech(ref)
    local leech = table.remove(self.activeLeeches, 1)
    if not leech then
        return
    end

    table.insert(self.vacantLeeches, leech.index)

    local name = ("Leech - %d"):format(leech.index)
    local shape = ref.sceneNode:getObjectByName(name)
    if not shape then
        return
    end

    local parent = assert(shape.parent) ---@cast parent niNode
    parent:detachChild(shape)
end

---@return boolean
function Leeches:anyActive()
    return next(self.activeLeeches) ~= nil
end

---@return number
function Leeches:numActive()
    return #self.activeLeeches
end

return Leeches
