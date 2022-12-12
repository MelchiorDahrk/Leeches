local utils = require("leeches.utils")
local Leeches = require("leeches.leeches")

local TICK_RATE = 0.25
local ATTACH_CHANCE = 1.0

---@type table<tes3reference, boolean>
local leechedReferences = {}

event.register("loaded", function()
    timer.start({
        iterations = -1,
        duration = TICK_RATE,
        callback = function()
            if tes3.player.cell.isInterior
                or tes3.getRegion().id ~= "Bitter Coast Region"
            then
                return
            end
            local timestamp = tes3.getSimulationTimestamp()
            for ref in utils.activeNpcReferences() do
                if ref.position.z < -20
                    and math.random() < ATTACH_CHANCE
                then
                    local leeches = Leeches.getOrCreate(ref)
                    leeches:addLeech(ref, timestamp)
                    leechedReferences[ref] = true
                end
            end
        end,
    })
end)

event.register("loaded", function()
    timer.start({
        iterations = -1,
        duration = TICK_RATE,
        callback = function()
            local timestamp = tes3.getSimulationTimestamp()
            for ref in pairs(leechedReferences) do
                local leeches = ref.data.leeches
                if leeches then
                    leeches:removeExpired(ref, timestamp)
                end
                -- clean up when all leeches were removed
                if not ref.data.leeches then
                    leechedReferences[ref] = nil
                end
            end
        end,
    })
end)

event.register("referenceDeactivated", function(e)
    leechedReferences[e.reference] = nil
end)
