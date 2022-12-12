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

function this.activeNpcReferences()
    return coroutine.wrap(function()
        coroutine.yield(tes3.player)
        for _, cell in ipairs(tes3.getActiveCells()) do
            for ref in cell:iterateReferences(tes3.objectType.npc) do
                if not ref.disabled or ref.deleted then
                    coroutine.yield(ref)
                end
            end
        end
    end)
end

return this
