local addonName, vm = ...
local frameTr
--local functions
local  createTransmitter
vm.Assistant = {
    go = function()
        if frameTr == nil then 
            createTransmitter()
        elseif frameTr:IsVisible() then
            print('hide tr')
            frameTr:Hide()
        else 
            print('show tr')
            frameTr:Show()
        end
        colorise()
    end
}

function createTransmitter()
    print('create tr')
    frameTr = CreateFrame('Frame', nil, UIParent)
    local dim = 100
    frameTr:SetSize(dim, dim)
    frameTr:SetPoint('TOPLEFT', 0, 0)
    frameTr:SetBackdrop({
        bgFile =  [[Interface\Buttons\WHITE8x8]]
    })
    frameTr:SetScript("OnUpdate", update)
end

function colorise()
    local x, y = GetPlayerMapPosition('player')
    local azimuth = GetPlayerFacing()
    -- local angle = azimuth / (2 * 3.1415)
    -- frameTr:SetBackdropColor(x, y, (azimuth  * 180 / 3.14) / 360)
    frameTr:SetBackdropColor(x, y, azimuth / 10)
    -- print(azimuth  * 180 / 3.14)
end

function update()
    colorise()
    -- print('update')
end 
