local addonName, vm = ...
local findForm 
--local functions
local creteForm
vm.Find = {
    form = function()
        if findForm == nil then
            createForm()
        end
        findForm:Show()
    end
}

function createForm()
    findForm = CreateFrame('Frame', 'VadeMecum_Find', UIParent)
    findForm:SetPoint('CENTER')
    findForm:SetSize(260, 50)
    findForm:SetBackdrop(vm.Config.backDrop)
    findForm:SetBackdropColor(0, 0, 0, 0.7)
    findForm:EnableKeyboard(true)
    findForm:SetScript('OnKeyUp', function(self, key)
        if (key == 'ESCAPE') and self:IsVisible() then
            self:Hide()
        end
    end)

    local targetName = CreateFrame("EditBox", nil, findForm, 'InputBoxTemplate')
    targetName:SetSize(160, 30)
    targetName:SetPoint('TOPLEFT', 20, -10)
    targetName:SetScript("OnEscapePressed", function(self)
        self:GetParent():Hide()
    end)
    targetName:SetHistoryLines(10)
    targetName:Show()
    local message = findForm:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    
    message:SetPoint(targetName:GetPoint())
    message:Hide()
    local btn = CreateFrame("Button", 'VadeMecum_Find_Go', findForm , 'SecureActionButtonTemplate, UIPanelButtonTemplate')
    btn:SetPoint('LEFT', targetName, 170, 0)
    btn:SetSize(60, 30)
    btn:SetText('Find')
    btn:SetAttribute("type", "macro")
    btn:SetScript('PreClick', function()
        targetName:AddHistoryLine(targetName:GetText())
        if IsShiftKeyDown() then
            targetName:Show()
            message:Hide()
        else 
            targetName:Hide()
            message:SetText('"' .. targetName:GetText() .. '"' .."\n" .. 'shift + click to change')
            message:Show()
        end    
        local mt = "/target " .. targetName:GetText() .. "\n" .."/run local n, r = UnitName('target')  if n then SetRaidTarget('target', 2) end"
        btn:SetAttribute("macrotext", mt)
    end)
    btn:Show()
end