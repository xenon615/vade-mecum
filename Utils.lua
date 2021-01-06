local addonName, vm = ...
vm.Utils = {
    dump = function (o)
        if type(o) == 'table' then
           local s = '{ '
           for k,v in pairs(o) do
              if type(k) ~= 'number' then k = '"'..k..'"' end
              s = s .. '['..k..'] = ' .. vm.Utils.dump(v) .. ','
           end
           return s .. '} '
        else
           return tostring(o)
        end
    end,
    formatCoords = function(x, y)
        return vm.Utils.round(x * 100, 2) .. " / " .. vm.Utils.round(y * 100, 2)
    end,
    round = function(float, digits)
        local mult = 10 ^ (digits or 0)
        return math.floor(float * mult + 0.5) / mult
        -- return floor(float + 0.5)
    end,
    showTooltip = function (marker, tooltip, full)
        tooltip:SetOwner(marker)
        local line = full == nil  and strsub(VadeMecum_Notes[marker.id].note, 1 , 20) .. "..." or VadeMecum_Notes[marker.id].note
        tooltip:AddLine(line)
        tooltip:SetFrameLevel(tooltip:GetParent():GetFrameLevel() + 1)
        tooltip:Show()
    end,
    cursorMapPosition = function()  -- stolen from MapCoords
        local c = GetCurrentMapContinent()
        if c < 1  then 
            return {c = 0, z = 0, x = 0, y = 0}
        end   
        local scale = WorldMapDetailFrame:GetEffectiveScale()
		local width = WorldMapDetailFrame:GetWidth()
		local height = WorldMapDetailFrame:GetHeight()
		local centerX, centerY = WorldMapDetailFrame:GetCenter()
		local x, y = GetCursorPosition()
		local adjustedX = (x / scale - (centerX - (width/2))) / width
        local adjustedY = (centerY + (height/2) - y / scale) / height
        local z = GetCurrentMapZone()
        if z == 0 then 
            ProcessMapClick(adjustedX, adjustedY)
            z = GetCurrentMapZone()
        end
        return {c = c, z = z, x = adjustedX, y = adjustedY}
    end
}

