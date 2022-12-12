local utils = require("leeches.utils")
local Leeches = require("leeches.leeches")

local TICK_RATE = 0.25
local ATTACH_CHANCE = 1.0

---@type table<tes3reference, boolean>
local leechedReferences = {}

local function attachLeeches(timestamp)
    for ref in utils.bitterCoastActorRefs() do
        if ref.position.z < -20
            and math.random() < ATTACH_CHANCE
        then
            local leeches = Leeches.getOrCreate(ref)
            leeches:addLeech(ref, timestamp)
            leechedReferences[ref] = true

            -- sound tests
            if ref == tes3.player then
                if leeches:numActive() == 1 then
                    tes3.removeSound({ reference = ref, sound = "leech_sound2" })
                    tes3.playSound({ reference = ref, sound = "leech_sound1", loop = true })
                end
                if leeches:numActive() == 10 then
                    tes3.removeSound({ reference = ref, sound = "leech_sound1" })
                    tes3.playSound({ reference = ref, sound = "leech_sound2", loop = true })
                end
            end
        end
    end
end

local function detachLeeches(timestamp)
    for ref in pairs(leechedReferences) do
        local leeches = ref.data.leeches
        if leeches then
            leeches:removeExpired(ref, timestamp)
        end
        -- clean up when all leeches were removed
        if leeches:numActive() == 0 then
            ref.data.leeches = nil
            leechedReferences[ref] = nil
        end
    end
end

event.register("loaded", function()
    timer.start({
        iterations = -1,
        duration = TICK_RATE,
        callback = function()
            local timestamp = tes3.getSimulationTimestamp()
            detachLeeches(timestamp)
            attachLeeches(timestamp)
        end,
    })
end)

event.register("referenceDeactivated", function(e)
    leechedReferences[e.reference] = nil
end)
