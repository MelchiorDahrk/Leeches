local Leeches = require("leeches.leeches")

local PHYSICS_FPS = 1 / 60 -- 30 fps

--- TODO: make leeches continue falling after reloading?
local fallingLeeches = {}

--- Allow shaking off leeches by attacking.
---
---@param e attackEventData
local function onAttack(e)
    local leeches = Leeches.get(e.reference)
    if leeches == nil then
        return
    end

    local leech = leeches:getOldestActiveLeech()
    if leech == nil then
        return
    end

    local shape = leech:getSceneNode(e.reference)
    if not shape then
        return
    end

    local t = shape.worldTransform
    local orientation = t.rotation:toEulerXYZ()

    local ref = tes3.createReference({
        object = "leech_ingred",
        cell = e.reference.cell,
        position = t.translation,
        orientation = orientation,
    })

    local vfx = tes3.createVisualEffect({
        object = "VFX_Leech",
        position = t.translation,
        lifespan = 10,
    })

    -- Track the ingredient and its associated vfx.
    fallingLeeches[ref] = vfx.effectNode

    leeches:removeLeech(e.reference, leech)
end
event.register("attack", onAttack)

--- Implements leeches visually falling.
---
local function onPhysicsTick()
    for ref, vfxNode in pairs(fallingLeeches) do
        ---@cast ref tes3reference
        ---@cast vfxNode niNode

        -- Snap reference to the NiGravity-driven particle vertex.
        local particles = vfxNode:getObjectByName("Particles")
        local vertex = particles.data.vertices[1]
        local t = vfxNode.worldTransform
        ref.position = t.rotation * t.scale * vertex + t.translation

        -- Detect if the reference has collided with the ground.
        local rayhit = tes3.rayTest({
            root = tes3.game.worldLandscapeRoot,
            position = ref.position,
            direction = { 0, 0, -1 },
        })

        -- No ground exists? How do we handle this gracefully?
        if rayhit == nil then
            fallingLeeches[ref] = nil
            ref:delete()
            return
        end

        -- When close to the ground snap to it and stop tracking.
        if ref.position:distance(rayhit.intersection) <= 10 then
            ref.position = rayhit.intersection
            fallingLeeches[ref] = nil
        end
    end
end
event.register("loaded", function()
    timer.start({
        iterations = -1,
        duration = PHYSICS_FPS,
        callback = onPhysicsTick,
    })
end)
