local log = require("leeches.log")
local utils = require("leeches.utils")
local physics = require("leeches.physics")

local Leech = require("leeches.leech")

---@alias LeechIndex number
---@alias LeechExpireTime number

--- A collection of leeches attached to a reference.
---
---@class Leeches
---@field activeLeeches Leech[] The currently active leeches, sorted according to their age.
---@field vacantLeeches LeechIndex[] The indices of the vacant leech slots.
local Leeches = {}
Leeches.__index = Leeches

--- Create a new leeches collection.
---
---@return Leeches
function Leeches.new()
    local data = {
        activeLeeches = {},
        vacantLeeches = utils.shuffle(utils.range(#utils.getAttachPoints())),
    }
    return setmetatable(data, Leeches)
end

--- Get the leeches collection for the given reference.
---
---@return Leeches|nil
function Leeches.get(ref)
    if ref.supportsLuaData then
        local leeches = ref.data.leeches
        return leeches and setmetatable(leeches, Leeches)
    end
end

--- Get the leeches collection for the given reference, creating it if necessary.
---
---@return Leeches
function Leeches.getOrCreate(ref)
    local leeches = Leeches.get(ref)
    if leeches == nil then
        leeches = Leeches.new()
        ref.data.leeches = leeches
    end
    return leeches
end

--- Iterate over all active leeches.
---
---@return fun():Leech
function Leeches:iterActiveLeeches()
    return coroutine.wrap(function()
        for _, leech in pairs(self.activeLeeches) do
            coroutine.yield(setmetatable(leech, Leech))
        end
    end)
end

--- Adds a new leech to the given reference, if possible.
---
---@param ref tes3reference
function Leeches:addLeech(ref, timestamp)
    local index = table.remove(self.vacantLeeches)
    if index == nil then -- all indices are active
        return
    end

    -- Add the leech.
    local leech = Leech:new(index, timestamp)
    table.insert(self.activeLeeches, leech)

    -- Create visuals.
    if ref.sceneNode then
        leech:addVisuals(ref)
    end

    -- Create sounds.
    if ref == tes3.player then
        self:addSounds(ref)
    end
end

--- Remove the given leech from the given reference.
---
---@param ref tes3reference
---@param leech Leech
function Leeches:removeLeech(ref, leech)
    local success = table.removevalue(self.activeLeeches, leech)
    if success == nil then
        log:warn("Failed to remove leech: %s", leech)
        return
    end
    table.insert(self.vacantLeeches, leech.index)

    physics.createFallingLeech(ref, leech)

    -- Detach Visuals.
    local name = leech:getName()
    for sceneNode in utils.get1stAnd3rdSceneNode(ref) do
        local shape = sceneNode:getObjectByName(name)
        if shape then
            shape.parent:detachChild(shape)
        end
    end

    -- Remove Sounds.
    if self:numActive() == 0 then
        self:removeSounds(ref)
        ref.data.leeches = nil
    end
end

--- Remove all leeches from the reference that have expired according to the given timestamp.
---
---@param ref tes3reference
---@param timestamp TimeStamp
function Leeches:removeExpired(ref, timestamp)
    while self:numActive() > 0 do
        local leech = self:getOldestActiveLeech()
        if timestamp < leech.expireTime then
            return
        end
        self:removeLeech(ref, leech)
        tes3.messageBox("Leech Expired! (%s) (%d)", ref, self:numActive())
    end
end

---@raturn Leech|nil
function Leeches:getOldestActiveLeech()
    local leech = self.activeLeeches[1]
    if leech ~= nil then
        return setmetatable(leech, Leech)
    end
end

---@return number
function Leeches:numActive()
    return #self.activeLeeches
end

---@param ref tes3reference
function Leeches:addSounds(ref)
    if self:numActive() == 1 then
        tes3.removeSound({ reference = ref, sound = "leech_sound2" })
        tes3.playSound({ reference = ref, sound = "leech_sound1", loop = true })
    end
    if self:numActive() == 9 then
        tes3.removeSound({ reference = ref, sound = "leech_sound1" })
        tes3.playSound({ reference = ref, sound = "leech_sound2", loop = true })
    end
end

---@param ref tes3reference
function Leeches:removeSounds(ref)
    tes3.removeSound({ reference = ref, sound = "leech_sound1" })
    tes3.removeSound({ reference = ref, sound = "leech_sound2" })
end

function Leeches:__tojson(state)
    return json.encode({
        activeLeeches = self.activeLeeches,
        vacantLeeches = self.vacantLeeches,
    }, state)
end

return Leeches
