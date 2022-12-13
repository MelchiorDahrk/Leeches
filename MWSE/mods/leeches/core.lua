local utils = require("leeches.utils")
local Leeches = require("leeches.leeches")

local TICK_RATE = 0.25
local ATTACH_CHANCE = 1.0

---@type table<tes3reference, boolean>
local leechedReferences = {}

--- Attach leeches to any actors currently standing in scum who fail their roll.
---
---@param timestamp number
local function globalAttachLeeches(timestamp)
    for ref in utils.bitterCoastActorRefs() do
        if utils.isInsideScum(ref)
            and math.random() < ATTACH_CHANCE
        then
            local leeches = Leeches.getOrCreate(ref)
            leeches:addLeech(ref, timestamp)
            leechedReferences[ref] = true
            -- tes3.messageBox("Leech Acquired! (%s) (%d)", ref, leeches:numActive())
        end
    end
end

--- Detach leeches that are past their expireTime from all actors.
---
---@param timestamp number
local function globalDetachLeeches(timestamp)
    for ref in pairs(leechedReferences) do
        local leeches = Leeches.get(ref)
        if leeches then
            leeches:removeExpired(ref, timestamp)
            -- clean up when all leeches were removed
            if leeches:numActive() == 0 then
                ref.data.leeches = nil
                leechedReferences[ref] = nil
            end
        end
    end
end

--- Timer to periodically run the globalAttachLeeches/globalDetachLeeches functions.
---
event.register("loaded", function()
    timer.start({
        iterations = -1,
        duration = TICK_RATE,
        callback = function()
            local timestamp = tes3.getSimulationTimestamp()
            globalDetachLeeches(timestamp)
            globalAttachLeeches(timestamp)
        end,
    })
end)

--- Stop tracking references if they get deactivated.
---
event.register("referenceDeactivated", function(e)
    leechedReferences[e.reference] = nil
end)
