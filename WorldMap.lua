local addonName, vm = ...

local overlayFrame, markers, tooltip = nil, {}, nil

-- local functions
local  placeMarker, getMarker, placeMarker, leaveMarker, enterMarker, clickMarker

vm.WorldMap = {
    display  = function()
        for k, v in pairs(VadeMecum_Notes) do
            placeMarker(k, VadeMecum_Notes[k])
        end   
        if tooltip == nill then
            tooltip = CreateFrame('GameTooltip', 'VadeMecum_tt', WorldMapFrame, 'GameTooltipTemplate');
            tooltip:Hide();
        end    
        VadeMecumMapOverlayParent:Show()
        overlayFrame:Show()
    end
}

-- +++

function placeMarker(index, note)
    marker = getMarker(index) 
    marker:SetAlpha(1)
    marker:SetWidth(16)
    marker:SetHeight(16)
    marker.id = index
    local texture = marker:GetNormalTexture()
    local color = vm.Config.Colors[note.color] or {1,1,1}
    texture:SetVertexColor(color[1],color[2],color[3], 0.6)
    vm.Astrolabe:PlaceIconOnWorldMap(WorldMapButton, marker, note.continent, note.zone, note.posX, note.posY)
end

-- +++

function enterMarker(marker)
    vm.Utils.showTooltip(marker, tooltip)
end

-- +++

function leaveMarker ()
    tooltip:Hide()
end

-- +++

function clickMarker(marker)
    vm.Utils.showTooltip(marker, tooltip, true)
end

-- +++

function getMarker(index)
    local marker = markers[index]
    if marker == nil then
        if  overlayFrame == nil then
            overlayFrame = CreateFrame("Frame", nil, VadeMecumMapOverlayParent, "VadeMecumrMapOverlayTemplate")

            -- overlayFrame:EnableKeyboard(true)
            -- overlayFrame:SetScript('OnKeyUp', function(this, key)
            --     if (key == 'N') and IsShiftKeyDown() then
            --         vm.Notes.add()
            --     end
            -- end)

        end
        marker = CreateFrame("Button" , nil, overlayFrame, "VadeMecumrMarkerTemplate")
        marker:SetID(index)
        marker:SetScript('OnEnter', function() enterMarker(this) end)
        marker:SetScript('OnLeave', function() leaveMarker() end)
        marker:SetScript('OnClick', function() clickMarker(this) end)
        markers[index] = marker
    end        
    return marker
end
