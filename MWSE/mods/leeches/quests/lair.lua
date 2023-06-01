local LAIR_CELL = tes3.getCell({ id = "Hlormaren, Cultist Lair" })

---@return mgeShaderHandle?
local function getShader()
    return mge.shaders.find({ name = "leeches_waterLayer" })
        or mge.shaders.load({ name = "leeches_waterLayer" })
end

---@param enabled boolean
local function toggleShader(enabled)
    local shader = assert(getShader())
    if shader.enabled ~= enabled then
        shader.enabled = enabled
    end
end

---@param enabled boolean
local function toggleMusic(enabled)
    if enabled then
        tes3.streamMusic({
            path = "leeches/lair.mp3",
            situation = tes3.musicSituation.uninterruptible,
        })
    else
        tes3.streamMusic({
            path = "leeches/silence.mp3",
            situation = tes3.musicSituation.explore,
        })
    end
end

--- Toggle the shader and music when entering or leaving the lair.
---
---@param e cellChangedEventData
local function onCellChanged(e)
    local isLair = e.cell == LAIR_CELL
    local wasLair = e.previousCell == LAIR_CELL
    if isLair and not wasLair then
        toggleShader(true)
        toggleMusic(true)
    elseif wasLair and not isLair then
        toggleShader(false)
        toggleMusic(false)
    end
end
event.register("cellChanged", onCellChanged)


--- Ensure music track repeats while in the lair.
---
---@param e musicSelectTrackEventData
local function onMusicSelectTrack(e)
    if tes3.player.cell == LAIR_CELL then
        e.music = "leeches/lair.mp3"
        e.situation = tes3.musicSituation.uninterruptible
        return false
    end
end
event.register("musicSelectTrack", onMusicSelectTrack, { priority = 1000 })
