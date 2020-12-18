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
        -- return format("%1.1f", vm.Utils.round(x * 1000) / 10) .. "/" .. format("%1.1f", vm.Utils.round(y * 1000) / 10)
        -- return format("%1.1f", vm.Utils.round(x * 100, 2) ) .. "/" .. format("%1.1f", vm.Utils.round(y * 100))
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
    end
    
}

