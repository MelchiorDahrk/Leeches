local utils = require("leeches.utils")

--- Dynamic state to be restored when a cutscene is finished.
---
---@class CutsceneRestoreState
---@field cell string
---@field position tes3vector3
---@field weather number
---@field volume number
---@field hour number
local CutsceneRestoreState = {}

---@return CutsceneRestoreState
function CutsceneRestoreState.get()
    local wc = tes3.worldController
    return {
        cell = tes3.player.cell.id,
        position = tes3.player.position:copy(),
        weather = wc.weatherController.currentWeather.index,
        volume = wc.audioController.volumeMusic,
        hour = wc.hour.value,
    }
end

--- Manages starting and canceling cutscenes.
---
---@class CutscenesManager
---@field name string
---@field active boolean
---@field controller niTimeController?
local CutscenesManager = {}
CutscenesManager.__index = CutscenesManager

---@param name string
function CutscenesManager:start(name)
    if CutscenesManager.active then
        return
    end

    -- save restore state
    local data = tes3.player.tempData
    if data.leeches_cutscene_restore_state == nil then
        data.leeches_cutscene_restore_state = CutsceneRestoreState.get()
    end

    -- set to raining
    utils.setWeather(tes3.weather.thunder)

    -- set night hour
    --- TODO: Can we should fake this with shaders or lighting instead?
    utils.setCurrentHour(2)

    -- enable music
    tes3.streamMusic({
        path = "leeches\\" .. name .. ".mp3",
        situation = tes3.musicSituation.uninterruptible,
        crossfade = 0.0,
    })

    -- enable music volume
    local ac = tes3.worldController.audioController
    ac.volumeMusic = math.max(ac.volumeMusic, 0.8)

    -- enable shader
    local shader = mge.shaders.load({ name = "leeches_cinematics" })
    if shader then
        shader.enabled = true
    end

    -- disable interface
    tes3.worldController.menuController.mainRoot.sceneNode.appCulled = true

    -- disable controls
    tes3.mobilePlayer.controlsDisabled = true

    -- disable collision
    tes3.mobilePlayer.movementCollision = false
    tes3.mobilePlayer.mobToMobCollision = false

    -- load animation source
    local cutscene = tes3.loadMesh("leeches\\" .. name .. ".nif"):clone() --[[@as niNode]]
    local animation = cutscene.children[1] --[[@as niTriShape]]

    -- hide exported geometry
    animation.stencilProperty = niStencilProperty.new()
    animation.stencilProperty.enabled = true
    animation.stencilProperty.testFunc = ni.stencilTestFunction.never

    -- attach to scene graph
    local root = tes3.worldController.vfxManager.worldVFXRoot
    root:attachChild(cutscene)
    root:update()

    -- reset animation timing
    animation:update({ controllers = true, time = 0.0 })
    animation.controller.phase = 0 -- block the "random" flag

    -- set as active
    self.name = name
    self.active = true
    self.controller = animation.controller
end

function CutscenesManager:cancel()
    local data = tes3.player.tempData
    local state = data.leeches_cutscene_restore_state
    if state == nil then
        mwse.log("[DEBUG] Leeches: Invalid cinematic restore state detected.")
    else
        -- restore weather
        utils.setWeather(state.weather)

        -- restore hour
        utils.setCurrentHour(state.hour)

        -- restore music
        tes3.streamMusic({
            path = "leeches\\silence.mp3",
            situation = tes3.musicSituation.explore,
            crossfade = 0.0,
        })

        -- restore music volume
        tes3.worldController.audioController.volumeMusic = state.volume

        -- restore cell
        timer.delayOneFrame(function()
            tes3.positionCell({
                reference = tes3.player,
                teleportCompanions = false,
                cell = state.cell,
                position = state.position,
            })
        end)
    end

    -- cleanup state
    data.leeches_cutscene_restore_state = nil

    -- disable shader
    local shader = mge.shaders.find({ name = "leeches_cinematics" })
    if shader then
        shader.enabled = false
    end

    -- enable interface
    tes3.worldController.menuController.mainRoot.sceneNode.appCulled = false

    -- enable controls
    tes3.mobilePlayer.controlsDisabled = false

    -- enable collision
    tes3.mobilePlayer.movementCollision = true
    tes3.mobilePlayer.mobToMobCollision = true

    -- disable animations
    pcall(function()
        local sceneNode = self.controller.target.parent
        local sceneRoot = tes3.worldController.vfxManager.worldVFXRoot
        sceneRoot:detachChild(sceneNode)
        self.controller:setTarget(nil) ---@diagnostic disable-line
    end)

    -- set as inactive
    self.name = ""
    self.active = false
    self.controller = nil
end

--- Handles camera updates and state changes during cutscenes.
---
---@param e cameraControlEventData
local function onCameraControl(e)
    if not CutscenesManager.active then
        return
    end

    -- If we're in a cutscene and no restore state exists, a reload happened.
    local state = tes3.player.tempData.leeches_cutscene_restore_state
    if state == nil then
        mwse.log("[DEBUG] Leeches: Reload during cinematic detected.")
        CutscenesManager:cancel()
        return
    end

    local controller = CutscenesManager.controller
    if controller == nil then
        mwse.log("[DEBUG] Leeches: Invalid cinematic controller detected.")
        CutscenesManager:cancel()
        return
    end

    if controller.lastScaledTime > controller.highKeyFrame then
        mwse.log("[DEBUG] Leeches: Animation Finished!")
        CutscenesManager:cancel()
        return
    end

    -- Get the camera transforms from the cuscene controller.
    local node = assert(CutscenesManager.controller.target)
    local position = node.worldTransform.translation
    local rotation = node.worldTransform.rotation

    -- Apply camera transforms.
    e.armCameraTransform.translation = position
    e.armCameraTransform.rotation = rotation

    -- Without this rain won't follow the camera.
    tes3.player.position = position
end
event.register(tes3.event.cameraControl, onCameraControl)

--- Prevents saving while a cutscene is active.
---
---@param e saveEventData
local function onSave(e)
    if CutscenesManager.active then
        e.block = true
    end
end
event.register(tes3.event.load, onSave, { priority = 700000 })

return CutscenesManager
