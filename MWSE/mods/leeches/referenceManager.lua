local activeManagers = {}

local referenceManager = {}
referenceManager.__index = referenceManager

function referenceManager:delete()
    table.removevalue(activeManagers, self)
end

---
--- Reference management
---

local allActiveReferences = {}

local function onReferenceActivated(e)
    local reference = e.reference

    allActiveReferences[reference] = true

    for _, manager in ipairs(activeManagers) do
        manager.references[reference] = true
        if (manager.onActivated and (manager.filter == nil or manager.filter(reference))) then
            local extraData = manager.onActivated(reference)
            if (extraData ~= nil) then
                manager.references[reference] = extraData
            end
        end
    end
end
event.register(tes3.event.referenceActivated, onReferenceActivated)

local function onReferenceDeactivated(e)
    local reference = e.reference

    allActiveReferences[reference] = nil

    for _, manager in ipairs(activeManagers) do
        manager.references[reference] = nil
        if (manager.onDeactivated) then
            manager.onDeactivated(reference)
        end
    end
end
event.register(tes3.event.referenceDeactivated, onReferenceDeactivated)

---
--- New APIs
---

local function createReferenceManager(params)
    params = params or {}

    local manager = setmetatable({}, referenceManager)
    manager.filter = params.filter
    manager.onActivated = params.onActivated
    manager.onDeactivated = params.Deactivate
    manager.references = {}

    -- Make sure lazy-made managers get a trigger for references already active.
    if (manager.onActivated) then
        for reference, _ in pairs(allActiveReferences) do
            if (manager.filter == nil or manager.filter(reference)) then
                manager.onActivated(reference)
            end
        end
    end

    table.insert(activeManagers, manager)

    return manager
end

return {
    createReferenceManager = createReferenceManager,
}
