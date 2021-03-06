local addonName, vm = ...
vm.Config = {
    MinimapSize = {
        indoor = {
            [0] = 300, -- scale
            [1] = 240, -- 1.25
            [2] = 180, -- 5/3
            [3] = 120, -- 2.5
            [4] = 80,  -- 3.75
            [5] = 50,  -- 6
        },
        outdoor = {
            [0] = 466 + 2/3, -- scale
            [1] = 400,       -- 7/6
            [2] = 333 + 1/3, -- 1.4
            [3] = 266 + 2/6, -- 1.75
            [4] = 200,       -- 7/3
            [5] = 133 + 1/3, -- 3.5
        },
    },
    Colors = {
        blue = {0,0,1},
        green = {0,1,0},
        cyan = {0,1,1},
        red = {1,0,0},
        magenta = {1,0,1},
        yellow = {1,1,0},
        white = {1,1,1}
    },
    Fields = {'continent', 'zone', 'posX', 'posY', 'note', 'color'},
    Separator = '<=>',
    backDrop = {
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 5,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    }
}