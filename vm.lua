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
    end
end

function init () 
    SlashCmdList["VADEMECUM"] = function()  
        vm.Notes.display()
    end
    SLASH_VADEMECUM1 = '/vm' 
    VadeMecum_Notes = VadeMecum_Notes or {}
    vm.Astrolabe = DongleStub("Astrolabe-0.4")
    vm.MiniMap.display()
    print(addonName .. " Loaded. Type /vm for notes list")
end

-- +++

function start()
    local main = CreateFrame("Frame", "VadeMecum")
    main:RegisterEvent("ADDON_LOADED")
    main:RegisterEvent("WORLD_MAP_UPDATE")
    main:SetScript("OnEvent", event)
end 


start();


