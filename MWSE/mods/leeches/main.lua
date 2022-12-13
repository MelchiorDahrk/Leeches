local function onInitialized()
    if debug.log(tes3.isModActive("Leeches.esp")) then
        dofile("leeches.core")
        dofile("leeches.physics")
    end
end
event.register("initialized", onInitialized)
