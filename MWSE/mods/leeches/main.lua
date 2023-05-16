local function onInitialized()
    if tes3.isModActive("Leeches.esp") then
        dofile("leeches.core")
        dofile("leeches.physics")
    end
end
event.register("initialized", onInitialized)
