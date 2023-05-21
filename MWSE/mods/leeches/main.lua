local function onInitialized()
    if tes3.isModActive("Leeches.esp") then
        -- mcm
        dofile("leeches.mcm")
        -- mechanics
        dofile("leeches.core")
        dofile("leeches.physics")
        -- quests
        dofile("leeches.quests")
    end
end
event.register("initialized", onInitialized)
