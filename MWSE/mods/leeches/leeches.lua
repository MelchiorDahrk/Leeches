local utils = require("leeches.utils")
local Leech = require("leeches.leech")

---@alias LeechIndex number
---@alias LeechExpireTime number

---@class Leeches
---@field activeLeeches Leech[]
---@field vacantLeeches LeechIndex[]
local Leeches = {}
Leeches.__index = Leeches

---@return Leeches
function Leeches.new()
    local data = {
        activeLeeches = {},
        vacantLeeches = utils.shuffle(utils.range(#utils.getAttachPoints())),
    }
    return setmetatable(data, Leeches)
end

---@return Leeches|nil
function Leeches.get(ref)
    return assert(ref.data).leeches
end

---@return Leeches
function Leeches.getOrCreate(ref)
    local data = assert(ref.data)
    data.leeches = data.leeches or Leeches.new()
    return data.leeches
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

    -- Create leech.

    local leech = Leech:new(index, timestamp)
    table.insert(self.activeLeeches, leech)

    -- Trigger Sounds.

    self:addSound(ref)

    -- Attach Visuals.

    local attachPoints = utils.getAttachPoints()
    local attachNode = assert(attachPoints[index])

    local shape = utils.getLeechMesh()
    shape.translation = attachNode.translation
    shape.rotation = attachNode.rotation
    shape.scale = attachNode.scale
    shape.name = leech:sceneNodeName()

    for sceneNode in utils.get1stAnd3rdSceneNode(ref) do
        local bone = sceneNode:getObjectByName(attachNode.parent.name)
        bone:attachChild(shape:clone())
        bone:update()
        bone:updateEffects()
        bone:updateProperties()
    end
end

---@param ref tes3reference
---@param timestamp TimeStamp
function Leeches:removeExpired(ref, timestamp)
    while self:numActive() > 0 do
        local leech = self:getOldestActiveLeech()
        if timestamp < leech.expireTime then
            return
        end
        self:removeLeech(ref, leech)
    end
end

---@param ref tes3reference
function Leeches:removeLeech(ref, leech)
    table.removevalue(self.activeLeeches, leech)
    table.insert(self.vacantLeeches, leech.index)

    -- Remove Sounds.
    if self:numActive() == 0 then
        self:removeSound(ref)
    end

    -- Detach Visuals.
    ---@cast leech Leech
    local name = leech:sceneNodeName()
    for sceneNode in utils.get1stAnd3rdSceneNode(ref) do
        local shape = sceneNode:getObjectByName(name)
        if shape then
            shape.parent:detachChild(shape)
        end
    end
end

function Leeches:getOldestActiveLeech()
    return self.activeLeeches[1]
end

---@return boolean
function Leeches:anyActive()
    return next(self.activeLeeches) ~= nil
end

---@return number
function Leeches:numActive()
    return #self.activeLeeches
end

---@param ref tes3reference
function Leeches:addSound(ref)
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
function Leeches:removeSound(ref)
    tes3.removeSound({ reference = ref, sound = "leech_sound1" })
    tes3.removeSound({ reference = ref, sound = "leech_sound2" })
end

return Leeches
