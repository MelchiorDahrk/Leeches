local this = {}

---@type niNode
local LEECH_MESH = nil

---@type niAVObject[]
local ATTACH_POINTS = {}

function this.range(n)
    local t = {}
    for i = 1, n do
        t[#t + 1] = i
    end
    return t
end

function this.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

---@return niNode
function this.getLeechMesh()
    if LEECH_MESH == nil then
        LEECH_MESH = assert(tes3.loadMesh("leeches\\leech.nif"))
    end
    return LEECH_MESH:clone() ---@diagnostic disable-line
end

---@return niAVObject[]
function this.getAttachPoints()
    if not next(ATTACH_POINTS) then
        local mesh = tes3.loadMesh("leeches\\xbase_anim_leeches.nif")
        for node in table.traverse(mesh.children) do
            if node:isInstanceOfType(ni.type.NiTriShape) then
                table.insert(ATTACH_POINTS, node)
            end
        end
    end
    return ATTACH_POINTS
end

function this.bitterCoastActorRefs()
    return coroutine.wrap(function()
        if this.isBitterCoastRegion(tes3.player.cell) then
            coroutine.yield(tes3.player)
        end
        for _, cell in ipairs(tes3.getActiveCells()) do
            if this.isBitterCoastRegion(cell) then
                for ref in cell:iterateReferences(tes3.objectType.npc) do
                    if not ref.disabled or ref.deleted then
                        coroutine.yield(ref)
                    end
                end
            end
        end
    end)
end

---@param cell tes3cell
function this.isBitterCoastRegion(cell)
    return not (cell.isInterior or cell.region.id ~= "Bitter Coast Region")
end

function this.get1stAnd3rdSceneNode(ref)
    return coroutine.wrap(function()
        if ref == tes3.player then
            coroutine.yield(tes3.player1stPerson.sceneNode)
        end
        coroutine.yield(ref.sceneNode)
    end)
end

--- TODO: make this more robust.
function this.isInsideScum(ref)
    return ref.position.z < -20
end

return this
