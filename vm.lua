local addonName, vm = ...
vm.Astrolabe = {}

-- local functions
local event, init, start

function event(self, event, ...) 
    if event == "ADDON_LOADED" and ... ==  addonName then
        init()
    elseif event == "WORLD_MAP_UPDATE" then
        if (vm.Astrolabe and  vm.Astrolabe.WorldMapVisible) then 
            vm.WorldMap.display()
        end
    elseif event == 'CHAT_MSG_ADDON' then
        addonMessage(...)
    end
end

function addonMessage(prefix, message, type, sender)
    if prefix == 'VadeMecum' then
        vm.Notes.importRequest(message, sender)
    end
end

function init () 
    SlashCmdList["VADEMECUM"] = function(msg)
        if msg == '' then 
            vm.Notes.display()
        elseif msg == 'assist' then
            vm.Assistant.go()
        end
        
    end
    SLASH_VADEMECUM1 = '/vm' 
    VadeMecum_Notes = VadeMecum_Notes or {}
    VadeMecum_Settings = VadeMecum_Settings or {}
    vm.Astrolabe = DongleStub("Astrolabe-0.4")
    SetMapToCurrentZone()
    vm.MiniMap.display()
    print(addonName .. " Loaded. Type /vm for notes list")
    
end

-- +++

function start()
    local main = CreateFrame("Frame", "VadeMecum")
    main:RegisterEvent("ADDON_LOADED")
    main:RegisterEvent("WORLD_MAP_UPDATE")
    main:RegisterEvent("CHAT_MSG_ADDON")
    main:SetScript("OnEvent", event)
end 


start();


