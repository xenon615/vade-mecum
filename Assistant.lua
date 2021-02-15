local addonName, vm = ...
local gFrame, gems, turn, nodes, nodeIdx
local resType, reset = 'HERB', false 
--local functions
local  createTransmitter, colorise, update, event, fillNodes, regScripts
vm.Assistant = {
    go = function()
        if gFrame == nil then 
            createTransmitter()
        end
        regScripts(true)
        fillNodes()
    end,
    next = function()
        if nodeIdx == #nodes then
            nodeIdx =   1 
        else 
            nodeIdx =  nodeIdx + 1
        end
        reset = false
        print('index', nodeIdx)
    end,
    switchRestype = function()
        resType = resType == 'HERB' and 'MINE' or 'HERB'
        fillNodes()
    end,
    settings = function()
        if gFrame == nill then
            createTransmitter()
        end
        regScripts(false)
        local scale = vm.Utils.round(UIParent:GetEffectiveScale(), 4)
        print(scale)
        
        local mmw = Minimap:GetWidth() / 2 
        local mmx, mmy = vm.Utils.round(scale * (Minimap:GetLeft() + mmw)), vm.Utils.round(scale * (Minimap:GetTop() - mmw))
        print(mmx, mmy)
        gems[1]:SetTexture(scale, mmx / 2000 , mmy / 1000)
    end

}

function regScripts(start)
    if start then
        gFrame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
        gFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
        gFrame:SetScript('OnEvent', event)
        gFrame:SetScript("OnUpdate", update)
    else 
        gFrame:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
        gFrame:UnregisterEvent('ZONE_CHANGED_NEW_AREA')
        gFrame:SetScript('OnEvent', nil)
        gFrame:SetScript("OnUpdate", nil)
    end    
end

function event(self, event, ...)
    if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        combatEvent(...)
    elseif event == 'ZONE_CHANGED_NEW_AREA' then
        reset = true
        fillNodes()
    end
    
end

function combatEvent(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20)
    -- print(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20)
    if p4 == UnitName('player') then
        if p2 == 'SPELL_CAST_FAILED' then
            if (string.find(p12, '\xD0\xBF\xD0\xB5\xD1\x80\xD0\xB5\xD0\xB4') ~= 0 ) then
                turn = 1
            end
        elseif p2 == 'SPELL_CAST_START' then
            -- "SPELL_CAST_SUCCESS"
            print('cast ok')
            turn = 0
        end
    elseif p2 == 'UNIT_DIED' then
        turn = 0
    end
end

function createTransmitter()
    print('create tr')
    local dim = 20
    local gCount = 6
    gFrame = CreateFrame('Frame', nil, UIParent)
    gFrame:SetPoint('TOPLEFT', 0, 0)
    gFrame:SetSize(gCount * dim, dim)
    gFrame:Show()
    gems = {}
    for i = 1, gCount do
        gems[i] = gFrame:CreateTexture()
        gems[i]:SetSize(dim, dim)
        gems[i]:SetPoint('TOPLEFT', (i - 1) * (dim), 0)
        gems[i]:Show()
    end
end

function colorise()
    local x, y = GetPlayerMapPosition('player')
    --  /run print(GetUnitPitch('player'))4
    --  /run print(GetPlayerFacing())
    local azimuth = GetPlayerFacing()
    local pitch = GetUnitPitch('player')
    local x1, x2 = math.modf(x * 255)
    local y1, y2 = math.modf(y * 255)
    if not reset  then
        gems[1]:SetTexture(x1 / 255, x2, azimuth / 7)
    else 
        gems[1]:SetTexture(0, 0, 0)
    end

    gems[2]:SetTexture(y1 / 255, y2, pitch / 4 + 0.5)
    -- gems[3]:SetTexture((turn == 1 and 0.8 or 0) + (IsFalling() and 0.2 or 0), (IsMounted() and 0.8 or 0) + (IsFlying() and 0.2 or 0),  (UnitAffectingCombat("player") and 0.8 or 0) + (UnitExists("target") and 0.2 or 0))
    gems[3]:SetTexture(IsMounted() and 1 or 0, IsFlying() and 1 or 0, IsFalling() and 1 or 0)
    gems[4]:SetTexture(UnitAffectingCombat("player") and 1 or 0, UnitExists("target") and 1 or 0, turn)

    if nodes[nodeIdx] ~= nil then 
        x1, x2 = math.modf(nodes[nodeIdx][1] * 255)
        y1, y2 = math.modf(nodes[nodeIdx][2] * 255)
        gems[5]:SetTexture(x1 / 255, x2, 0)
        gems[6]:SetTexture(y1 / 255, y2, 0)
    end
end

function update()
    colorise()
end 

--  ---

function closestNode(node)
    local md = 1000
    local nodeIdx = 0
    for k, v in ipairs(nodes) do
        local d = math.sqrt(math.pow(math.abs(node[1] - v[1]), 2 ) + math.pow(math.abs(node[2] - v[2]), 2))
        if d < md then
            md = d
            nodeIdx = k
        end
    end
    return nodeIdx
end

--  ---

function fillNodes()
    local continent, zone = GetCurrentMapContinent(), GetCurrentMapZone()
    local x, y = GetPlayerMapPosition('player')
    nodes = {}
    nodeIdx =   1 
    local minXY, cornerIndex, i  = 10, 1, 1
    
    for nodeId, gatherType, num in Gatherer.Storage.ZoneGatherNames(continent, zone) do
        if gatherType == resType then
               for index, xPos, yPos in Gatherer.Storage.ZoneGatherNodes(continent, zone, nodeId) do
                if minXY > (xPos  + yPos) then
                    minXY = xPos + yPos
                    cornerIndex = i
                end
                table.insert(nodes, {xPos, yPos})
                i = i + 1 
            end    
        end
    end

    if (#(nodes) > 0) then 
        local sortedNodes = {}
        table.insert(sortedNodes, table.remove(nodes, cornerIndex))

        while #(nodes) > 0 do
            table.insert(sortedNodes, table.remove(nodes, cornerIndex))
            cornerIndex = closestNode(sortedNodes[#sortedNodes])
        end

        nodes = sortedNodes

        nodeIdx = closestNode({x, y})
        print(#nodes,'of', resType)
        print('Closest node is ' .. nodeIdx .. ' ( ' .. vm.Utils.round(nodes[nodeIdx][1], 2) .. ' / ' .. vm.Utils.round(nodes[nodeIdx][2], 2) .. ')')
        nodeIdx = nodeIdx > 1 and nodeIdx -1 or #(nodes)
    end
end