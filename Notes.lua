local addonName, vm = ...
local currentPage = 1
local rowsPerPage = 10
local pagesCount = 0 
local items = {}
local listFrame, formFrame;

-- local functions 
local formatLocation, dump, sort, getPage, delete, edit, save, createForm, createList, getCoords

vm.Notes = {
    display = function()
        if listFrame == nil then
            createList()
        end
        listFrame:Show()
    end
}

-- +++

function dump ()
    table.foreach(VadeMecum_Notes, function(k,v)
        table.foreach(v, print)
        end
    )
end

-- +++

function sort ()
    table.sort(VadeMecum_Notes, function(a,b)
        return formatLocation(a.continent, a.zone)  < formatLocation(b.continent, b.zone)
    end
    )
end

-- +++

function getPage(page)
    local notesCount = getn(VadeMecum_Notes) 
    pagesCount = ceil(notesCount / rowsPerPage)

    if (page < 1) or (page > pagesCount) then 
        return
    end 
    for i = 1, rowsPerPage do
        local ii = rowsPerPage * (page - 1) + i
        if ii > notesCount then
            items[i].row:Hide()
        else
            items[i].row:Show()
            items[i].zone:SetText(formatLocation(VadeMecum_Notes[ii].continent, VadeMecum_Notes[ii].zone))
            items[i].coords:SetText(vm.Utils.formatCoords(VadeMecum_Notes[ii].posX, VadeMecum_Notes[ii].posY))
            items[i].note:SetText(strsub(VadeMecum_Notes[ii].note, 1 , 100))
        end
    end
    currentPage = page
    VadeMecum_Pages:SetText(currentPage .. "/" .. pagesCount)
    vm.MiniMap.checkZone();
end

-- +++

function delete(i)
    table.remove(VadeMecum_Notes, i)
    getPage(currentPage);
end

-- +++

function edit(index)
    if formFrame == nil then
        createForm()
    end
    local text = ""
    local ii = 0
    if index ~= 0 then
        ii = rowsPerPage * (currentPage - 1) + index
        text = VadeMecum_Notes[ii].note
    end
    VadeMecum_Form_Note:SetText(text)
    VadeMecum_Edit_Save:SetScript("OnClick", function() save(ii) getPage(currentPage) end)
    formFrame:Show()
end

-- +++

function save(index)
    local posX, posY = GetPlayerMapPosition("player")
    if index == 0 then 
        local rec = {
            continent = GetCurrentMapContinent(),
            zone = GetCurrentMapZone(),
            posX = posX,
            posY = posY,
            note = VadeMecum_Form_Note:GetText()
        }
        table.insert(VadeMecum_Notes, rec)
        sort();
    else
        VadeMecum_Notes[index].note = VadeMecum_Form_Note:GetText()
    end     
    formFrame:Hide()
end

-- +++

function createForm()
    formFrame = CreateFrame("Frame")
    formFrame:Hide();
    local backDrop = {
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
    formFrame:SetSize(300, 300)
    formFrame:SetPoint("CENTER", 0, 0)
    formFrame:SetBackdrop(backDrop)
    formFrame:SetBackdropColor(0, 0, 0, 0.5)
    formFrame:SetFrameStrata("DIALOG")
    
-- ---
    
    local cont = CreateFrame("Frame", nil, formFrame)
    cont:SetSize(formFrame:GetWidth() - 20, 200)
    cont:SetPoint("TOPLEFT", 10, -40)
    cont:SetBackdrop(backDrop)
    cont:SetBackdropColor(0, 0, 0, 0.5)

-- ---

    local scroll = CreateFrame("ScrollFrame", "VadeMecum_Form_Scroll", cont, "UIPanelScrollFrameTemplate")
    scroll:SetSize(cont:GetWidth() - 40 , 180)
    scroll:SetPoint("TOPLEFT", 10, -10)

-- ---

    local note = CreateFrame("EditBox", "VadeMecum_Form_Note", scroll)
    note:SetMultiLine(true)
    note:SetWidth(scroll:GetWidth() - 20)
    note:SetPoint("TOPLEFT", 10, -10)
    note:SetAutoFocus(true)
    note:SetText("test")
    note:SetCursorPosition(0)
    note:SetFont("Fonts\\FRIZQT__.TTF", 13)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("CENTER")
    scroll:SetScrollChild(note)
    note:SetScript("OnTextChanged", function(self, input)
        local h = self:GetHeight()
        local hs = VadeMecum_Form_Scroll:GetHeight() 
        if h > hs then
            VadeMecum_Form_Scroll:SetVerticalScroll(h - hs)
        end
    end)
-- ---

    local t = formFrame:CreateFontString("VadeMecum_Form_Coords", "OVERLAY", "GameFontNormal")
    t:SetPoint("TOPLEFT", 10, -10)

-- ---

    local rb = CreateFrame("Button","VadeMecum_Edit_Refresh", formFrame, "UIPanelButtonTemplate")
    rb:SetHeight(24)
    rb:SetWidth(60)
    rb:SetPoint("TOPRIGHT", -10, -5)
    rb:SetText("Refresh")
    rb:SetScript("OnClick", function()
        getCoords()
    end)

-- ---

local sb = CreateFrame("Button","VadeMecum_Edit_Save", formFrame, "UIPanelButtonTemplate")
    sb:SetHeight(24)
    sb:SetWidth(60)
    sb:SetPoint("BOTTOMRIGHT", -10, 10)
    sb:SetText("Save")
    sb:SetScript("OnClick", function()
        saveNote()
    end)

-- ---

local sb = CreateFrame("Button","VadeMecum_Edit_Close", formFrame, "UIPanelButtonTemplate")
    sb:SetHeight(24)
    sb:SetWidth(60)
    sb:SetPoint("BOTTOMLEFT", 10, 10)
    sb:SetText("Close")
    sb:SetScript("OnClick", function()
        formFrame:Hide()
        getPage(currentPage)
    end)

end

-- ---

function createList()
    listFrame = CreateFrame("Frame")
    listFrame:Hide();
    local backDrop = {
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
    listFrame:SetSize(800, 500)
    listFrame:SetPoint("CENTER", 0, 0)
    listFrame:SetBackdrop(backDrop)
    listFrame:SetBackdropColor(0, 0, 0, 0.5)
    local container = CreateFrame("Frame", "VadeMecum_List_Container", listFrame)
    container:SetSize(listFrame:GetWidth() - 60 , 400)
    container:SetPoint("CENTER", 0, 0)
    container:SetBackdrop(backDrop)
    container:SetBackdropColor(0, 0, 0, 0.5)
    local lineHeight = 40
    for i = 1, rowsPerPage do 
        items[i] = {}
        items[i].row = CreateFrame("Frame", nil, container)
        items[i].row:SetSize(container:GetWidth(), lineHeight)
        items[i].row:SetPoint("TOPLEFT", 0, (i - 1) * -lineHeight)
        items[i].row:SetBackdrop(backDrop)
        items[i].row:SetBackdropColor(0, 0, 0, 0.5)
        
        items[i].zone = items[i].row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        items[i].zone:SetPoint("LEFT", 10, 0)
        items[i].zone:SetText("")
        items[i].zone:SetWidth(200)
        items[i].zone:SetHeight(lineHeight)
        items[i].zone:SetJustifyH("LEFT")

        items[i].coords = items[i].row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        items[i].coords:SetPoint("LEFT", 200, 0)
        items[i].coords:SetText("")
        items[i].coords:SetWidth(100)
        items[i].coords:SetHeight(lineHeight)

        items[i].note = items[i].row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        items[i].note:SetPoint("LEFT", 300, 0)
        items[i].note:SetText("")
        items[i].coords:SetWidth(100)
        items[i].coords:SetHeight(lineHeight)

        local db = CreateFrame("Button", nil, items[i].row, "UIPanelButtonTemplate")
        db:SetHeight(24)
        db:SetWidth(60)
        db:SetPoint("RIGHT", -65, 0)
        db:SetText("Edit")
        db:SetScript("OnClick", function()
            edit(i)
        end)
        
        local db = CreateFrame("Button", nil, items[i].row, "UIPanelButtonTemplate")
        db:SetHeight(24)
        db:SetWidth(60)
        db:SetPoint("RIGHT", -5, 0)
        db:SetText("Del")
        db:SetScript("OnClick", function()
            delete(i)
        end)

        if i > getn(VadeMecum_Notes) then 
            items[i].row:Hide();
        end
    end
    local nb = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
    nb:SetHeight(24)
    nb:SetWidth(60)
    nb:SetPoint("BOTTOMLEFT", 10, 10)
    nb:SetText("Prev")
    nb:SetScript("OnClick", function()
        getPage(currentPage - 1)
    end)

    local pb = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
    pb:SetHeight(24)
    pb:SetWidth(60)
    pb:SetPoint("BOTTOMRIGHT", -10, 10)
    pb:SetText("Next")
    pb:SetScript("OnClick", function()
        getPage(currentPage + 1)
    end)

    local pb = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
    pb:SetHeight(24)
    pb:SetWidth(60)
    pb:SetPoint("TOPLEFT", 10, -10)
    pb:SetText("Add")
    pb:SetScript("OnClick", function()
        edit(0)
    end)

    local pb = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
    pb:SetHeight(24)
    pb:SetWidth(60)
    pb:SetPoint("TOPRIGHT", -10, -10)
    pb:SetText("Close")
    pb:SetScript("OnClick", function()
        listFrame:Hide()
    end)
    listFrame:CreateFontString("VadeMecum_Pages", "OVERLAY", "GameFontNormal"):SetPoint("BOTTOM", -10, 10)
    getPage(currentPage)
end

-- +++

function formatLocation(continent, zone) 
    local continentNames, key, val = { GetMapContinents()} 
    local zoneNames , key, val = { GetMapZones(continent)}
    return continentNames[continent] .. ', ' .. zoneNames[zone]
end

-- +++

function getCoords()
    local posX, posY = GetPlayerMapPosition("player")
    VadeMecum_Form_Coords:SetText(shwcrd(posX) .. " / " .. shwcrd(posY));
end
