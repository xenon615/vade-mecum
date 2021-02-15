local addonName, vm = ...
local currentPage, rowsPerPage, pagesCount, itemEdited = 1, 10, 0, 0
local items = {}
local listFrame, formFrame, mateFrame

-- local functions 
local formatLocation, formatDistance, dump, sort, getPage, delete, edit, save, createForm, createList, showOnMap, setMate, pack, unpack, import

StaticPopupDialogs["VadeMecum_Del_Confirm"] = {
    text = "Delete this note?",
    button1 = "Yes",
    button2 = "No",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}
StaticPopupDialogs["VadeMecum_Import_Confirm"] = {
    button1 = "Accept",
    button2 = "Decline",
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
        if listFrame:IsVisible() then 
            listFrame:Hide()
        else 
            listFrame:Show()
            getPage(currentPage)
        end
    end,
    importRequest = function(message, sender)
        StaticPopupDialogs["VadeMecum_Import_Confirm"].text = 'Note from ' .. sender .. ' received'
        StaticPopupDialogs["VadeMecum_Import_Confirm"].OnAccept = function(self)
            table.insert(VadeMecum_Notes, unpack(message))
            sort();
            if listFrame and listFrame:IsVisible() then
                getPage(currentPage)
            end
        end	
        StaticPopup_Show('VadeMecum_Import_Confirm')
    end,
    add = function()
        local coords = vm.Utils.cursorMapPosition()
        if coords.c ~= 0 then
            ToggleFrame(WorldMapFrame)
            edit(0, coords)
        end
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
    SetMapToCurrentZone()
    local posX, posY = GetPlayerMapPosition("player")
    local continent = GetCurrentMapContinent()
    local zone = GetCurrentMapZone()
    for i = 1, rowsPerPage do
        local ii = rowsPerPage * (page - 1) + i
        if ii > notesCount then
            items[i].row:Hide()
        else
            items[i].row:Show()
            items[i].zone:SetText(formatLocation(VadeMecum_Notes[ii].continent, VadeMecum_Notes[ii].zone))
            items[i].coords:SetText(vm.Utils.formatCoords(VadeMecum_Notes[ii].posX, VadeMecum_Notes[ii].posY))
            items[i].note:SetText(VadeMecum_Notes[ii].note and strsub(VadeMecum_Notes[ii].note, 1 , 300) or '')
            items[i].distance:SetText(formatDistance(
                continent, zone, posX, posY, 
                VadeMecum_Notes[ii].continent, VadeMecum_Notes[ii].zone, VadeMecum_Notes[ii].posX, VadeMecum_Notes[ii].posY))
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

function edit(index, coords)
    if formFrame == nil then
        createForm()
    end
    local text, color_slug, ii, posX, posY  = '', 'white', 0, 0, 0
    local  continent, zone

    if index ~= 0 then
        ii = rowsPerPage * (currentPage - 1) + index
        text = VadeMecum_Notes[ii].note
        color_slug = VadeMecum_Notes[ii].color or 'white'
        posX =  VadeMecum_Notes[ii].posX
        posY =  VadeMecum_Notes[ii].posY
        continent = VadeMecum_Notes[ii].continent
        zone = VadeMecum_Notes[ii].zone
    else 
        if coords == nil then
            posX, posY = GetPlayerMapPosition("player")
            continent = GetCurrentMapContinent()
            zone = GetCurrentMapZone()
        else 
            posX = coords.x
            posY = coords.y
            continent = coords.c
            zone = coords.z            
        end
    end

    formFrame.posX:SetText(vm.Utils.round(posX * 100, 4))
    formFrame.posY:SetText(vm.Utils.round(posY * 100, 4))

    local color = vm.Config.Colors[color_slug]
    formFrame.colorI:SetBackdropColor(color[1], color[2], color[3])
    formFrame.note:SetText(text)
    UIDropDownMenu_SetSelectedValue(formFrame.color, color_slug)
    UIDropDownMenu_SetSelectedValue(formFrame.continent, continent)
    UIDropDownMenu_SetSelectedValue(formFrame.zone, zone)
    local cname, zname = formatLocation(continent, zone, 1)
    VadeMecum_Edit_Continent_Button:SetText(cname)
    VadeMecum_Edit_Zone_Button:SetText(zname)
    itemEdited = ii
    formFrame:Show()
    if listFrame ~= nil and listFrame:IsVisible() then 
        listFrame:Hide()
    end
end

-- +++

function save(index)
    local posX, posY = GetPlayerMapPosition("player")
    posX = vm.Utils.round((tonumber(formFrame.posX:GetText()) or (posX * 100)) / 100, 6)
    posY = vm.Utils.round((tonumber(formFrame.posY:GetText()) or (posY * 100)) / 100, 6)
    local rec = {
        continent = UIDropDownMenu_GetSelectedValue(formFrame.continent) or GetCurrentMapContinent(),
        zone = UIDropDownMenu_GetSelectedValue(formFrame.zone) or GetCurrentMapZone(),
        posX = posX,
        posY = posY,
        note = formFrame.note:GetText(),
        color = UIDropDownMenu_GetSelectedValue(formFrame.color) or 'white'
    }
    if index == 0 then 
        table.insert(VadeMecum_Notes, rec)
    else
        VadeMecum_Notes[index] = rec
    end
    sort();
    formFrame:Hide()
end

-- +++

function showOnMap(index)
    local ii = rowsPerPage * (currentPage - 1) + index
    ToggleFrame(WorldMapFrame)
    SetMapZoom(VadeMecum_Notes[ii].continent, VadeMecum_Notes[ii].zone)
end

-- +++

function setMate(index)
    local ii = rowsPerPage * (currentPage - 1) + index
    itemEdited = ii
    if mateFrame == nil then
        createSetMate()
    end
    listFrame:Hide();
    mateFrame:Show();
end

-- +++

function pack(note)
    local separator = vm.Config.Separator
    local fields = vm.Config.Fields
    local result = note[fields[1]]
    for i = 2 , #(fields) do
        result = result .. separator .. note[fields[i]]
    end
    return result
end

-- +++

function unpack(s)
    local separator = vm.Config.Separator
    local fields = vm.Config.Fields
    result = {};
    local ii = 0
    for match in (s..separator):gmatch('([^' .. separator ..']+)') do
        ii = ii + 1
        result[fields[ii]] = ((fields[ii] == 'note') or (fields[ii] == 'color')) and match or tonumber(match);
    end
    return result
end

-- +++

function createSetMate()
    mateFrame = CreateFrame('Frame')
    mateFrame:Hide();
    local backDrop = {
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }

    mateFrame:SetSize(300, 50)
    mateFrame:SetPoint("CENTER", 0, 0)
    mateFrame:SetBackdrop(backDrop)
    mateFrame:SetBackdropColor(0, 0, 0, 0.8)
    mateFrame:SetFrameStrata("FULLSCREEN_DIALOG")

    local friend = CreateFrame('Frame', 'VadeMecum_Set_Mate', mateFrame, 'UIDropDownMenuTemplate')
    friend:SetFrameStrata("FULLSCREEN_DIALOG")
    friend:Show()
    local function clicked(self)
        local packed = pack(VadeMecum_Notes[itemEdited])
        SendAddonMessage('VadeMecum', packed, 'WHISPER', self.value);
        mateFrame:Hide()
        listFrame:Show()
    end
    local numberOfFriends, onlineFriends = GetNumFriends()
    local friends = {}
    for i = 1, onlineFriends  do
        local name = GetFriendInfo(i)
        table.insert(friends, name)
    end

    UIDropDownMenu_Initialize(friend, function(self, level)
        for k, v in pairs(friends) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.value = v
            info.func = clicked
            UIDropDownMenu_AddButton(info, level)
        end    
    end)

    mateFrame.friendI = createButton({
        parent = mateFrame,
        text = 'Friend',
        template = 'UIPanelButtonTemplate',
        name = 'VadeMecum_Set_MateI',
        size = {60,32},
        point = {"TOPLEFT",  10 , -10},
        onClick = function(self)
            ToggleDropDownMenu(1, nil, friend, self:GetName(), 0, 0)
        end
    })

    createButton({
        parent = mateFrame,
        texture = 'Interface\\Addons\\VadeMecum\\images\\del',
        size = {32,32},
        point = {"TOPRIGHT", -10, -10},
        onClick = function() mateFrame:Hide() listFrame:Show() end
    })
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
    formFrame:SetSize(600, 200)
    formFrame:SetPoint("CENTER", 0, 100)
    formFrame:SetBackdrop(backDrop)
    formFrame:SetBackdropColor(0, 0, 0, 0.8)
    -- formFrame:SetFrameStrata("FULLSCREEN_DIALOG")

-- --- =================================================================================================================================================
    
    local continentNames, key, val = { GetMapContinents() }

    formFrame.continent = createDropdown({
        name = 'VadeMecum_Edit_Continent',
        parent = formFrame,
        text = 'no continent',
        size = {180, 32},
        point = {"TOPLEFT",  10 , -10},
        choices = continentNames,
        func = function(self)
            VadeMecum_Edit_Zone_Button:Click()
        end,
    })

    formFrame.zone = createDropdown({
        name = 'VadeMecum_Edit_Zone',
        parent = formFrame,
        text = 'no zone1',
        size = {180, 32},
        point = {"TOPLEFT",  200 , -10},
        choices = function()
            local continent = UIDropDownMenu_GetSelectedValue(VadeMecum_Edit_Continent)
            local zoneNames
            if (continent == nil) then
                zoneNames , key, val = { GetMapZones(2)}
            else 
                zoneNames , key, val = { GetMapZones(continent)}
            end
            return zoneNames
        end,
    })
        
-- --- =====================================================================
    
    local slash = formFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slash:SetText('   /   ')
    slash:SetSize(slash:GetStringWidth(), 30)
    local editWidth = 75
   
    for k, v in ipairs({'posX', 'posY'}) do
        formFrame[v] = CreateFrame("EditBox", nil, formFrame, 'InputBoxTemplate')
        formFrame[v]:SetAutoFocus(false)
        formFrame[v]:SetSize(editWidth, 30)
        formFrame[v]:SetPoint("TOPLEFT",  400 +  ((k -1 ) * (editWidth + slash:GetWidth()))  , -10)
    end
    slash:SetPoint('TOPLEFT', 400 + editWidth, -10);

-- ---

    local cont = CreateFrame("Frame", nil, formFrame)
    cont:SetSize(formFrame:GetWidth() - 20, 80)
    cont:SetPoint("TOPLEFT", 10, -50)   
    cont:SetBackdrop(backDrop)
    cont:SetBackdropColor(0, 0, 0, 0.5)

-- ---

    local scroll = CreateFrame("ScrollFrame", "VadeMecum_Form_Scroll", cont, "UIPanelScrollFrameTemplate")
    scroll:SetSize(cont:GetWidth() - 40 , 60)
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
    local function clicked(self)
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
    colorI:SetPoint("BOTTOMLEFT",  10 , 40)
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
        if listFrame ~= nil then
            listFrame:Show()
            getPage(currentPage)
        end
    end)
-- ---

local sb = CreateFrame("Button","VadeMecum_Edit_Close", formFrame, "UIPanelButtonTemplate")
    sb:SetHeight(24)
    sb:SetWidth(60)
    sb:SetPoint("BOTTOMLEFT", 10, 10)
    sb:SetText("Close")
    sb:SetScript("OnClick", function()
        if listFrame ~= nil then
            formFrame:Hide()
            listFrame:Show()
        end
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
    local  listFrameWidth, listFrameHeight = 1000, 500
    listFrame:EnableKeyboard(true)
    listFrame:SetScript('OnKeyUp', function(self, key)
        if (key == 'ESCAPE') and self:IsVisible() then
            self:Hide()
        end
    end)
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

        items[i].row:EnableMouse(true)
        items[i].row:SetScript('OnEnter', function(self)
            self:SetBackdropColor(0,0,1, 0.4)
        end)
        items[i].row:SetScript('OnLeave', function(self)
            self:SetBackdropColor(0,0,0, 0.5)
        end)
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
        items[i].note:SetWidth(300)

        items[i].coords:SetWidth(100)
        items[i].coords:SetHeight(lineHeight)

        items[i].distance = items[i].row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        items[i].distance:SetPoint("RIGHT", -180, 0)
        items[i].distance:SetText("1000")

        items[i].color = CreateFrame("Frame", nil, items[i].row)
        items[i].color:SetSize(16,16)
        items[i].color:SetPoint("RIGHT", -120, 0)
        items[i].color:SetBackdrop({
            bgFile = [[Interface\Addons\VadeMecum\images\star]]
        })


        createButton({
            parent = items[i].row,
            texture = 'Interface\\Addons\\VadeMecum\\images\\send',
            size = {32,16},
            point = {"RIGHT", -75, 0},
            onClick = function() setMate(i) end
        })

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
        texture = 'Interface\\Addons\\VadeMecum\\images\\plus',
        size = {32,32},
        point = {"TOPLEFT", 10, -10},
        tooltip = 'Add new note',
        onClick = function() edit(0) end
    })

    createButton({
        parent = listFrame,
        texture = 'Interface\\Addons\\VadeMecum\\images\\del',
        size = {32,32},
        point = {"TOPRIGHT", -10, -10},
        tooltip = 'Close',
        onClick = function() listFrame:Hide() end
    })

    local mm = createButton({
        parent = listFrame,
        texture = 'Interface\\Addons\\VadeMecum\\images\\circle',
        size = {32,32},
        point = {"TOPLEFT", (listFrameWidth / 2) -16, -10},
        tooltip = 'Toggle minimap',
        onClick = function(self) 
            VadeMecum_Settings.MiniMap = not VadeMecum_Settings.MiniMap
            vm.MiniMap.standby(VadeMecum_Settings.MiniMap)
            local texture = self:GetNormalTexture()
            if VadeMecum_Settings.MiniMap then 
                texture:SetVertexColor(0,0,1,1)
            else 
                texture:SetVertexColor(1,1,1,1)
            end
        end
    })
    
    if VadeMecum_Settings.MiniMap then 
        mm:GetNormalTexture():SetVertexColor(0,0,1,1)
    else 
        mm:GetNormalTexture():SetVertexColor(1,1,1,1)
    end    
    
    mm:SetScript('OnLeave', function(self)
        local texture = self:GetNormalTexture()
        if VadeMecum_Settings.MiniMap then 
            texture:SetVertexColor(0,0,1,1)
        else 
            texture:SetVertexColor(1,1,1,1)
        end    
    end)
    listFrame:CreateFontString("VadeMecum_Pages", "OVERLAY", "GameFontNormal"):SetPoint("BOTTOM", -10, 10)

--  ---------------------------------------------------------------------------------------------------------------
    -- btn = CreateFrame("Button","myButton", UIParent ,"SecureActionButtonTemplate");
    -- btn:SetPoint('TOPLEFT', 100, 40)
    -- btn:SetSize(60, 30)
    -- btn:SetText('go')
    -- btn:SetAttribute("type","target");
    -- btn:SetAttribute("unit","nameExample");


-- -------------------------------------------------------------------------------------------------------------
end

-- +++

function formatLocation(continent, zone, separate) 
    local continentNames, key, val = { GetMapContinents()} 
    local zoneNames , key, val = { GetMapZones(continent)}
    if (separate == nil) then
        return (continentNames[continent] and zoneNames[zone]) and (continentNames[continent] .. ', ' .. zoneNames[zone]) or 'wrong location'
    else 
        return continentNames[continent], zoneNames[zone]
    end
end

-- +++

function formatDistance(c0, z0, x0, y0, c1, z1, x1, y1)
    if c0 ~= c1 then
        return 'so far'
    end
    return vm.Utils.round(vm.Astrolabe:ComputeDistance(c0, z0, x0, y0, c1, z1, x1, y1) or 0) .. ' m'
end

-- +++

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
            self:GetNormalTexture():SetVertexColor(0, 0.5, 1, 0.6)
            if params.tooltip ~= nil then
                GameTooltip:SetOwner(self)
                GameTooltip:AddLine(params.tooltip)
                GameTooltip:Show()
            end                
        end)
        b:SetScript('OnLeave', function(self)
            self:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
            if params.tooltip ~= nil then
                GameTooltip:Hide()
            end
        end)
    end
    return b
end

function createDropdown(params)
    local dropdown = CreateFrame('Frame', params.name, params.parent, 'UIDropDownMenuTemplate')
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    local button =  createButton({
        parent = params.parent,
        text = params.text,
        template = 'UIPanelButtonTemplate',
        name = params.name .. '_Button',
        size = params.size,
        point = params.point,
        onClick = function(self)
            ToggleDropDownMenu(1, nil, dropdown, self:GetName(), 0, 0)
        end
    })
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local choices  = type(params.choices) == 'function' and params.choices() or params.choices
        for k, v in pairs(choices) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.value = k
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                button:SetText(self:GetText())
                if params.func ~= nill then
                    params.func()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end    
    end)
    return dropdown
end