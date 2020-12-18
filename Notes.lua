local addonName, vm = ...
local currentPage, rowsPerPage, pagesCount, itemEdited = 1, 10, 0, 0
local items = {}
local listFrame, formFrame;

-- local functions 
local formatLocation, dump, sort, getPage, delete, edit, save, createForm, createList, showOnMap

StaticPopupDialogs["VadeMecum_Del_Confirm"] = {
    text = "Are you sure?",
    button1 = "Yes",
    button2 = "No",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
  }


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
    pagesCount = pagesCount == 0 and 1 or pagesCount
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
            local color = vm.Config.Colors[VadeMecum_Notes[ii].color] or {1,1,1}
            items[i].color:SetBackdropColor(color[1], color[2], color[3],1)
        end
    end
    currentPage = page
    VadeMecum_Pages:SetText(currentPage .. "/" .. pagesCount)
end

-- +++

function delete(i)
    local  ii = rowsPerPage * (currentPage - 1) + i
    StaticPopupDialogs["VadeMecum_Del_Confirm"].OnAccept = function(self)
        table.remove(VadeMecum_Notes, ii)
        getPage(currentPage);
    end,	
    StaticPopup_Show('VadeMecum_Del_Confirm')
end

-- +++

function edit(index)
    if formFrame == nil then
        createForm()
    end
    local text, color_slug, ii, posX, posY  = '', 'white', 0, 0, 0

    if index ~= 0 then
        ii = rowsPerPage * (currentPage - 1) + index
        text = VadeMecum_Notes[ii].note
        color_slug = VadeMecum_Notes[ii].color or 'white'
        posX =  VadeMecum_Notes[ii].posX
        posY =  VadeMecum_Notes[ii].posY
    else 
        posX, posY = GetPlayerMapPosition("player")
    end

    formFrame.posX:SetText(vm.Utils.round(posX * 100, 2))
    formFrame.posY:SetText(vm.Utils.round(posY * 100, 2))

    local color = vm.Config.Colors[color_slug]
    formFrame.colorI:SetBackdropColor(color[1], color[2], color[3])
    formFrame.note:SetText(text)
    UIDropDownMenu_SetSelectedValue(formFrame.color, color_slug)
    itemEdited = ii
    formFrame:Show()
    listFrame:Hide()
end

-- +++

function save(index)
    local posX, posY = GetPlayerMapPosition("player")
    local color = UIDropDownMenu_GetSelectedValue(formFrame.color) or 'white'
    if index == 0 then 
        local rec = {
            continent = GetCurrentMapContinent(),
            zone = GetCurrentMapZone(),
            posX = posX,
            posY = posY,
            note = formFrame.note:GetText(),
            color = color
        }
        table.insert(VadeMecum_Notes, rec)
        sort();
    else
        VadeMecum_Notes[index].posX = vm.Utils.round((tonumber(formFrame.posX:GetText()) or (posX * 100)) / 100, 4)
        VadeMecum_Notes[index].posY = vm.Utils.round((tonumber(formFrame.posY:GetText()) or (posY * 100)) / 100, 4)
        VadeMecum_Notes[index].note = formFrame.note:GetText()
        VadeMecum_Notes[index].color = color
    end     
    formFrame:Hide()
end

-- +++

function showOnMap(index)
    local ii = rowsPerPage * (currentPage - 1) + index
    ToggleFrame(WorldMapFrame)
    SetMapZoom(VadeMecum_Notes[ii].continent, VadeMecum_Notes[ii].zone)
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
    formFrame:SetSize(300, 400)
    formFrame:SetPoint("CENTER", 0, 0)
    formFrame:SetBackdrop(backDrop)
    formFrame:SetBackdropColor(0, 0, 0, 0.8)
    formFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    
-- ---
    
    local slash = formFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slash:SetText('   /   ')
    slash:SetSize(slash:GetStringWidth(), 30)
    local editWidth = 75
   
    for k, v in ipairs({'posX', 'posY'}) do
        formFrame[v] = CreateFrame("EditBox", nil, formFrame, 'InputBoxTemplate')
        formFrame[v]:SetAutoFocus(false)
        formFrame[v]:SetSize(editWidth, 30)
        formFrame[v]:SetPoint("TOPLEFT",  10 +  ((k -1 ) * (editWidth + slash:GetWidth()))  , -10)
    end
    slash:SetPoint('TOPLEFT', 10 + editWidth, -10);

-- ---

    local cont = CreateFrame("Frame", nil, formFrame)
    cont:SetSize(formFrame:GetWidth() - 20, 250)
    cont:SetPoint("TOPLEFT", 10, -60)   
    cont:SetBackdrop(backDrop)
    cont:SetBackdropColor(0, 0, 0, 0.5)

-- ---

    local scroll = CreateFrame("ScrollFrame", "VadeMecum_Form_Scroll", cont, "UIPanelScrollFrameTemplate")
    scroll:SetSize(cont:GetWidth() - 40 , 230)
    scroll:SetPoint("TOPLEFT", 10, -10)

-- ---

    local note = CreateFrame("EditBox", nil, scroll)
    scroll:SetScrollChild(note)
    note:SetMultiLine(true)
    note:SetWidth(scroll:GetWidth() - 20)
    note:SetPoint("TOPLEFT", 10, -10)
    note:SetAutoFocus(true)
    note:SetCursorPosition(0)
    note:SetFont("Fonts\\FRIZQT__.TTF", 13)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("CENTER")

    note:SetScript("OnTextChanged", function(self, input)
        local h = self:GetHeight()
        local hs = VadeMecum_Form_Scroll:GetHeight() 
        if h > hs then
            VadeMecum_Form_Scroll:SetVerticalScroll(h - hs)
        end
    end)
    formFrame.note = note

-- ---

    local colorF = CreateFrame('Frame', 'VadeMecum_Edit_Color', formFrame, 'UIDropDownMenuTemplate')
    colorF:SetFrameStrata("FULLSCREEN_DIALOG")
    colorF:Show()
    local function clicked(self)
        UIDropDownMenu_SetSelectedID(colorF, self:GetID())
        UIDropDownMenu_SetSelectedValue(colorF, self.value)
        local color = vm.Config.Colors[self.value]
        formFrame.colorI:SetBackdropColor(color[1], color[2], color[3])
    end

    
    UIDropDownMenu_Initialize(colorF, function(self, level)
        for k, v in pairs(vm.Config.Colors) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = k
            info.value = k
            info.colorCode = ("|cff%.2x%.2x%.2x"):format(v[1] * 255, v[2] * 255, v[3] * 255)
            info.func = clicked
            UIDropDownMenu_AddButton(info, level)
        end    
    end)

    local colorI = CreateFrame('Button','VadeMecum_Edit_ColorI', formFrame)
    colorI:SetPoint("BOTTOMLEFT",  10 , 60)
    colorI:SetSize(20,20)
    colorI:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }) 
    colorI:SetScript('OnClick', function(self, button, down) 
        ToggleDropDownMenu(1, nil, colorF, self:GetName(), 0, 0)
    end)


    formFrame.color = colorF
    formFrame.colorI = colorI
-- ---

local sb = CreateFrame("Button","VadeMecum_Edit_Save", formFrame, "UIPanelButtonTemplate")
    sb:SetHeight(24)
    sb:SetWidth(60)
    sb:SetPoint("BOTTOMRIGHT", -10, 10)
    sb:SetText("Save")
    sb:SetScript("OnClick", function()
        save(itemEdited)
        listFrame:Show()
        getPage(currentPage)
    end)

-- ---

local sb = CreateFrame("Button","VadeMecum_Edit_Close", formFrame, "UIPanelButtonTemplate")
    sb:SetHeight(24)
    sb:SetWidth(60)
    sb:SetPoint("BOTTOMLEFT", 10, 10)
    sb:SetText("Close")
    sb:SetScript("OnClick", function()
        formFrame:Hide()
        listFrame:Show()
        getPage(currentPage)
    end)

end

-- ---

function createButton(params)
    local b = CreateFrame("Button", params.name, params.parent, params.template)
    if params.texture then 
        b:SetNormalTexture(params.texture)
    end
    b:SetSize(params.size[1],params.size[2])
    b:SetPoint(params.point[1], params.point[2], params.point[3])
    if params.text then
        b:SetText(params.text)
    end
    b:SetScript("OnClick", params.onClick)
    if params.texture then 
        b:SetScript('OnEnter', function(self)
            self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.6)
            end)
        b:SetScript('OnLeave', function(self)
            self:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
        end)
    end
end


function createList()
    listFrame = CreateFrame("Frame")
    listFrame:Hide();
    local backDrop = {
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
    local  listFrameWidth, listFrameHeight = 800, 500

    listFrame:SetSize(listFrameWidth, listFrameHeight)
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

        items[i].color = CreateFrame("Frame", nil, items[i].row)
        items[i].color:SetSize(32,24)
        items[i].color:SetPoint("RIGHT", -100, 0)
        items[i].color:SetBackdrop(backDrop)
        items[i].row:EnableMouse(true)
        items[i].row:SetScript('OnEnter', function(self)
            self:SetBackdropColor(0,0,1, 0.4)
        end)
        items[i].row:SetScript('OnLeave', function(self)
            self:SetBackdropColor(0,0,0, 0.5)
        end)

        createButton({
            parent = items[i].row,
            texture = 'Interface\\Addons\\VadeMecum\\images\\arrow',
            size = {16,16},
            point = {"RIGHT", -55, 0},
            onClick = function() showOnMap(i) end
        })

        createButton({
            parent = items[i].row,
            texture = 'Interface\\Addons\\VadeMecum\\images\\pensil',
            size = {16,16},
            point = {"RIGHT", -32, 0},
            onClick = function() edit(i) end
        })
        
        createButton({
            parent = items[i].row,
            texture = 'Interface\\Addons\\VadeMecum\\images\\del',
            size = {16,16},
            point = {"RIGHT", -10, 0},
            onClick = function() delete(i) end
        })


        if i > getn(VadeMecum_Notes) then 
            items[i].row:Hide();
        end
    end

    createButton({
        parent = listFrame,
        texture = 'Interface\\Addons\\VadeMecum\\images\\prev',
        size = {32, 16},
        point = {"BOTTOMLEFT", 10, 10},
        onClick = function() getPage(currentPage - 1) end
    })

    createButton({
        parent = listFrame,
        texture = 'Interface\\Addons\\VadeMecum\\images\\next',
        size = {32,16},
        point = {"BOTTOMRIGHT", -10, 10},
        onClick = function() getPage(currentPage + 1) end
    })

    createButton({
        parent = listFrame,
        texture = 'Interface\\Addons\\VadeMecum\\images\\add',
        size = {32,32},
        point = {"TOPLEFT", 10, -10},
        onClick = function() edit(0) end
    })

    createButton({
        parent = listFrame,
        texture = 'Interface\\Addons\\VadeMecum\\images\\close',
        size = {32,32},
        point = {"TOPRIGHT", -10, -10},
        onClick = function() listFrame:Hide() end
    })

    createButton({
        parent = listFrame,
        texture = 'Interface\\Addons\\VadeMecum\\images\\' .. (VadeMecum_Settings.MiniMap and 'circle-g' or 'circle-y'),
        size = {32,32},
        point = {"TOPLEFT", (listFrameWidth / 2) -16, -10},
        onClick = function(self) 
            VadeMecum_Settings.MiniMap = not VadeMecum_Settings.MiniMap
            vm.MiniMap.standby(VadeMecum_Settings.MiniMap)
            self:SetNormalTexture('Interface\\Addons\\VadeMecum\\images\\' .. (VadeMecum_Settings.MiniMap and 'circle-g' or 'circle-y'))
        end
    })

    listFrame:CreateFontString("VadeMecum_Pages", "OVERLAY", "GameFontNormal"):SetPoint("BOTTOM", -10, 10)
    getPage(currentPage)
end

-- +++

function formatLocation(continent, zone) 
    local continentNames, key, val = { GetMapContinents()} 
    local zoneNames , key, val = { GetMapZones(continent)}
    return continentNames[continent] .. ', ' .. zoneNames[zone]
end
