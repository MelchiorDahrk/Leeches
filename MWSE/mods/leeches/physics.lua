local Leeches = require("leeches.leeches")

local PHYSICS_FPS = 1 / 60

local UP = tes3vector3.new(0, 0, 1)
local DOWN = tes3vector3.new(0, 0, -1)

local SPIN = tes3matrix33.new()
SPIN:toRotationZ(math.rad(120) * PHYSICS_FPS)

--- TODO: make leeches continue falling after reloading?
local fallingLeeches = {}

---@param vfxNode niNode
---@return niParticles, niPerParticleData
local function getParticle(vfxNode)
    local particles = vfxNode:getObjectByName("Particles") --[[@as niParticles]]
    local particle = particles.controller.particleData[1] ---@diagnostic disable-line
    return particles, particle
end

---@param ref tes3reference
local function createLeechVFX(ref)
    local vfx = tes3.createVisualEffect({
        object = "VFX_Leech",
        position = ref.position,
        lifespan = 10,
    })

    -- random initial momentum (30 to 60)
    local momentum = 30 + 30 * math.random()

    -- random upward bias (15% to 30%)
    local bias = 0.15 + 0.15 * math.random()
    local direction = ref.rightDirection:lerp(UP, bias)

    -- apply initial particle velocity
    local particles, particle = getParticle(vfx.effectNode)
    local r = particles.worldTransform.rotation:transpose()
    particle.velocity = r * direction * momentum

    return vfx
end

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
    if shape == nil then
        return
    end

    -- Create the leech reference.
    local t = shape.worldTransform
    local ref = tes3.createReference({
        object = "leech_ingred",
        cell = e.reference.cell,
        position = t.translation,
        orientation = t.rotation:toEulerXYZ(),
    })

    -- Create associated leech VFX.
    local vfx = createLeechVFX(ref)

    -- Track the reference with its associated vfx.
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

        -- Get position of gravity-driven particle.
        local particles = vfxNode:getObjectByName("Particles")
        local vertex = particles.data.vertices[1]
        local position = vfxNode.worldTransform * vertex

        -- Get orientation with some random spin added.
        local orientation = (SPIN * ref.sceneNode.rotation):toEulerXYZ()

        -- Detect if the reference has collided with the ground.
        local rayhit = tes3.rayTest({
            position = position,
            direction = DOWN,
            ignore = { tes3.game.worldPickRoot, tes3.player.sceneNode },
        })

        -- Assume this is ground level if there was no intersection.
        local intersection = rayhit and rayhit.intersection or position

        -- When close to the ground snap to it and stop tracking.
        if position:distance(intersection) <= 1 then
            fallingLeeches[ref] = nil
            position.z = position.z + ref.object.boundingBox.max.z
        end

        -- Apply updates
        ref.position = position
        ref.orientation = orientation
    end
end
event.register("loaded", function()
    -- TODO: Instead we could trigger on cell changed when intering a leech region.
    timer.start({
        iterations = -1,
        duration = PHYSICS_FPS,
        callback = onPhysicsTick,
    })
end)

--- Stop tracking references if they get deactivated.
---
event.register("referenceDeactivated", function(e)
    fallingLeeches[e.reference] = nil
end)
