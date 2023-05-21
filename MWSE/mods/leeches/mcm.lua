local config = require("leeches.config")

local function leaveMCM()
    tes3ui.getMenuOnTop()
        :findChild("MWSE:ModConfigMenu_Close")
        :triggerEvent("mouseClick")
    tes3ui.getMenuOnTop()
        :findChild("MenuOptions_Return_container")
        :triggerEvent("mouseClick")
end


local template = mwse.mcm.createTemplate({ name = "Leeches" })
template:saveOnClose("leeches", config)
template:register()

local preferences = template:createSideBarPage({ label = "Preferences" })
preferences.sidebar:createInfo({
    text = "Version 0.0.0\n\n"
        .. "Debug functions for development. Can only be used after loading in-game.",
})

local teleports = preferences:createCategory({ label = "Cells" })
teleports:createDropdown({
    description = "Teleport to the various cells created for this mod.",
    inGameOnly = true,
    options = {
        {
            label = "Detective's Office",
            value = {
                cell = "Balmora, Western Guard Tower North",
                position = { 4376.02, 3828.37, 14983.00 },
                orientation = { 0.00, 0.00, -1.57 },
            },
        },
        {
            label = "Crime Scene",
            value = {
                cell = "Balmora",
                position = { -25493.85, -10571.56, 962.00 },
                orientation = { 0.00, 0.00, -1.57 },
            },
        },
        {
            label = "Hlormaren, Sewers",
            value = {
                cell = "Hlormaren, Sewers",
                position = { 1165.00, -8.00, 130.00 },
                orientation = { 0.00, 0.00, -1.57 },
            },
        },
    },
    variable = mwse.mcm:createVariable({
        set = function(self, value)
            timer.frame.delayOneFrame(leaveMCM)

            tes3.positionCell({
                reference = tes3.player,
                cell = value.cell,
                position = value.position,
                orientation = value.orientation,
            })
        end,
    }),
})

local cutscenes = preferences:createCategory({ label = "Cutscenes" })
cutscenes:createButton({
    buttonText = "Crime Scene",
    description = "Shortcut for triggering the cutscene. Player must be in Balmora!",
    inGameOnly = true,
    callback = function()
        timer.frame.delayOneFrame(leaveMCM)

        local CustsceneManager = require("leeches.quests.cutscenes")
        CustsceneManager:start("cutscene_01")
    end,
})
