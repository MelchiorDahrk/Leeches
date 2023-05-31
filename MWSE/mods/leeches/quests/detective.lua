--- Make water droplets less synchronized.
local function offsetWaterDrops()
    local ref = tes3.getReference("leech_bucket_drip")
    if ref then
        tes3.setAnimationTiming({ reference = ref, timing = 2.0 })
    end
end

local function playSleepingAnimation()
    local detective = tes3.getReference("leech_private_eye_01")
    local chair = tes3.getReference("leech_office_chair")
    if not (detective and chair) then
        return
    end

    -- Offset height so we are at the chair's feet rather than its center.
    local position = chair.position:copy()
    position.z = position.z + chair.object.boundingBox.min.z

    -- Rotate 180 degrees so we face the correct direction for sitting.
    local orientation = chair.orientation:copy()
    orientation.z = orientation.z + math.rad(180)

    -- Center on the chair.
    detective.position = position
    detective.orientation = orientation

    -- Disable greeting/turning.
    detective.mobile.hello = 0

    -- Play the animation.
    tes3.playAnimation({
        reference = detective,
        group = tes3.animationGroup.idle9,
        mesh = "leeches\\k\\chair_sleeping.nif",
    })

    -- Play snoring sounds.
    tes3.playSound({
        reference = detective,
        sound = "leeches_male_snoring",
        loop = true,
    })
end
event.register(tes3.event.cellActivated, function(e)
    if e.cell.id == "Balmora, Detective's Office" then
        offsetWaterDrops()
        playSleepingAnimation()
    end
end)
