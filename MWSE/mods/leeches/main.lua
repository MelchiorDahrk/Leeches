local function onInitialized()
    if tes3.isModActive("Leeches.esm") then
        dofile("leeches.mcm")
        dofile("leeches.core")
        require("leeches.quests")
        require("leeches.physics")
    end
end
event.register("initialized", onInitialized)
