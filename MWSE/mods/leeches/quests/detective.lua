--- Get the position and orientation for the chair animation.
---@return tes3vector3, tes3vector3
local function getChairAnimationPosition()
    local chair = tes3.getReference("leeches_detective_chair")

    -- Offset height so we are at the chair's feet rather than its center.
    local position = chair.position:copy()
    position.z = position.z + chair.object.boundingBox.min.z

    -- Rotate 180 degrees so we face the correct direction for sitting.
    local orientation = chair.orientation:copy()
    orientation.z = orientation.z + math.rad(180)

    return position, orientation
end

local function playSleepingAnimation()
    local ref = tes3.getReference("leeches_detective")

    -- Center on the chair.
    ref.position, ref.orientation = getChairAnimationPosition()

    -- Disable greeting/turning.
    ref.mobile.hello = 0

    -- Play the animation.
    tes3.playAnimation({
        reference = ref,
        group = tes3.animationGroup.idle9,
        mesh = "leeches\\k\\chair_sleeping.nif",
    })

    -- Play snoring sounds.
    tes3.playSound({
        reference = ref,
        sound = "leeches_male_snoring",
        loop = true,
    })
end

event.register(tes3.event.cellChanged, function(e)
    if e.cell.id == "Balmora, Western Guard Tower North" then
        playSleepingAnimation()
    end
end)
