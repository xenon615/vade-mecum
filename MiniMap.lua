local addonName, vm = ...

local miniMapLastUpdate = 0
local markers = {}
-- local functions
local getMarker, enterMarker, leaveMarker, update, event

vm.MiniMap = {
    display = function()
        MiniMapUpdateFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
        MiniMapUpdateFrame:SetScript("OnEvent", event)
        MiniMapUpdateFrame:SetScript("OnUpdate", update)
        vm.MiniMap.checkZone()
     end,
    checkZone = function()
        if not VadeMecum_Settings.MiniMap then
            vm.MiniMap.standby(false)
            return
        end
        local continent, zone = GetCurrentMapContinent(), GetCurrentMapZone()
        for i = 1, #(VadeMecum_Notes) do
            if (VadeMecum_Notes[i].continent == continent) and (VadeMecum_Notes[i].zone == zone) then 
                vm.MiniMap.standby(true);
                return
            end
        end
        vm.MiniMap.standby(false);
    end,
    standby = function(what)
        if not what  then
            for i = 1, #(markers) do
                vm.Astrolabe:RemoveIconFromMinimap(markers[i])
            end
            MiniMapUpdateFrame:Hide()
        else 
            MiniMapUpdateFrame:Show()
        end
    end    
}

-- +++

function event(self, event, ...)
    vm.MiniMap.checkZone();
end 


function getMarker(index)
    local marker = markers[index]
	if  marker == nil then
		marker = CreateFrame("Button", nil, Minimap, "MiniMapMarkerTemplate")
        marker:SetID(index)
        marker:SetScript('OnEnter', function() enterMarker(this) end)
        marker:SetScript('OnLeave', function() leaveMarker() end)
        markers[index] = marker
	end
	return marker
end

-- +++

function enterMarker(marker)
    vm.Utils.showTooltip(marker, GameTooltip)
end

-- +++

function leaveMarker ()
    GameTooltip:Hide()
end

-- +++

function update()
    miniMapLastUpdate = miniMapLastUpdate + 5
    local needUpdate = false
    if miniMapLastUpdate > 1000 then
        miniMapLastUpdate = 0
        needUpdate = true
    end
    if needUpdate then
        local z = GetCurrentMapZone()
        local c = GetCurrentMapContinent()
        local px, py = GetPlayerMapPosition("player")
        local index = 0
        local maxDist = vm.Config.MinimapSize[vm.Astrolabe.minimapOutside and 'outdoor' or 'indoor'][Minimap:GetZoom()] / 2;
        
        for k, v in pairs(VadeMecum_Notes) do
            if (c == v.continent) and (v.zone == z) then
                local d = vm.Astrolabe:ComputeDistance(c, z, px, py, v.continent, v.zone, v.posX, v.posY) or 0
                if d < maxDist  then 
                    index = index + 1
                    local marker = getMarker(index)
                    marker.id = k
                    local texture = marker:GetNormalTexture()
                    local color = vm.Config.Colors[v.color] or {1,1,1}

                    texture:SetVertexColor(color[1], color[2], color[3], 0.6)
                    local result = vm.Astrolabe:PlaceIconOnMinimap(marker, v.continent, v.zone, v.posX, v.posY)
                end  
            end
        end
		for i = (index + 1), #(markers) do
			vm.Astrolabe:RemoveIconFromMinimap(markers[i])
		end
    end
end 

